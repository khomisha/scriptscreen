
tinymce.init({
	selector: 'textarea#mytextarea',
	height: 500,
    plugins: [
      'advlist', 'lists', 'anchor', 'autolink', 'link', 'image',
      'searchreplace', 'visualblocks', 'charmap', 'fullscreen', 'media', 'table', 'preview',
      'insertdatetime', 'help', 'wordcount', 'code'
    ],
    toolbar: 'undo redo | fontfamily fontsize |  blocks |' +
      'bold italic underline superscript subscript | alignleft aligncenter alignright alignjustify | forecolor backcolor |' +
      'bullist numlist outdent indent | link image table media | removeformat charmap code | searchreplace | help',
	init_instance_callback: function( editor ) {
		editor.execCommand( 'mceFullScreen' );
	},
	content_style: 'div { font-family:Courier New,Arial,sans-serif; font-size:12pt }',
	promotion: false,
	menubar: true,
	contextmenu: false,
	// 2
	//Use a local file picker in the Insert Image dialog
    file_picker_types: 'image',
    file_picker_callback: ( cb, value, meta ) => {
		const input = document.createElement( 'input' );
		input.type = 'file';
		input.accept = 'image/*';
		input.onchange = function ( ) {
			const file = this.files[ 0 ];
			insertImageFile( file );
		};
		input.click( );
    },
    setup: ( editor ) => {
		// Intercept drag & drop and embed as base64
		editor.on( 
			'drop', 
			( e ) => {
				const dt = e.dataTransfer;
				if( dt && dt.files && dt.files.length ) {
					e.preventDefault( );
					e.stopPropagation( );
					Array.from( dt.files ).forEach(
						( file ) => {
							if( file.type.startsWith( 'image/' ) ) {
								insertImageFile( file );
							}
						}
					);
				}
			}
		);

		// Optional: intercept paste from clipboard files to enforce our path.
		// paste_data_images already handles pasted images, but this keeps behavior consistent.
		editor.on(
			'paste', 
			( e ) => {
				const items = ( e.clipboardData || {} ).items || [];
				for( const it of items ) {
					if( it.kind === 'file' ) {
						const file = it.getAsFile( );
						if( file && file.type.startsWith( 'image/' ) ) {
							e.preventDefault( );
							insertImageFile( file );
						}
					}
				}
			}
		);
    },
});

let contentGenerator = null;
// Handle chunk requests
window.contentAPI.onChunkRequest(
	( ) => {
		try {
			// First request
			if( !tinymce.activeEditor.isDirty( ) ) {
				// nothing to save
				window.contentAPI.sendChunk( null );
				return;
			}

			if( !contentGenerator ) {
				const content = tinymce.activeEditor.getContent( );
				contentGenerator = createTextStream( content );
			}

			// Get next chunk
			const next = contentGenerator.next( );

			if( next.done ) {
				// Send null to signal end of stream
				window.contentAPI.sendChunk( null );
				contentGenerator = null;
			} else {
				window.contentAPI.sendChunk( next.value );
			}
		}
		catch( err ) {
			console.error( 'Error chunk request:', err );
		}
	}
);

function* createTextStream( content ) {
	const CHUNK_SIZE = 65536; // 64KB chunks
	let position = 0;
	while( position < content.length ) {
		const chunk = content.slice( position, position + CHUNK_SIZE );
		position += CHUNK_SIZE;
		yield chunk;
	}
}

// Efficient binary version for large content
function* createBinaryStream( content ) {
	const encoder = new TextEncoder( );
	const CHUNK_SIZE = 131072; // 128KB
	for( let i = 0; i < content.length; i += CHUNK_SIZE ) {
		const chunk = content.substring( i, i + CHUNK_SIZE );
		yield encoder.encode( chunk );
	}
}

let progress = 0;
// Handle loading events
window.contentAPI.onBeginLoading(
	( ) => {
		progress = 0;
		tinymce.activeEditor.setProgressState( true );
		//tinymce.activeEditor.setContent(''); // Clear editor
		tinymce.activeEditor.resetContent( );
		tinymce.EditorMode.set( 'readonly' ); // Prevent editing during load
	}
);

let buffer = "";
window.contentAPI.onLoadChunk(
	( chunk ) => {
		try {
			buffer += chunk;

			while( true ) {
				// Find first occurrence of '<img'
				const imgStart = buffer.indexOf( "<img" );

				// No '<img' at all -> insert everything as text and clear buffer
				if( imgStart === -1 ) {
					if( buffer.length > 0 ) {
						tinymce.activeEditor.insertContent( buffer );
						buffer = "";
					}
					break;
				}

				// If there's text before the image start, insert that first
				if( imgStart > 0 ) {
					const textPart = buffer.slice( 0, imgStart );
					tinymce.activeEditor.insertContent( textPart );
					buffer = buffer.slice( imgStart ); // keep the '<img...' part in buffer
					// continue to attempt extracting the image tag
				}

				// At this point buffer starts with '<img'
				const imgEnd = buffer.indexOf( ">" ); // find tag close
				if( imgEnd === -1 ) {
					// image tag not complete yet — wait for next chunk
					break;
				}

				// We have a complete <img ...> tag
				const imgTag = buffer.slice( 0, imgEnd + 1 );

				// Optional guard: ensure it's a data image (if required)
				// if (!/src\s*=\s*["']data:image/i.test(imgTag)) { /* handle non-data images if needed */ }

				// Insert whole <img> at once
				tinymce.activeEditor.insertContent( imgTag );

				// Remove the inserted tag from buffer and continue (there may be more content)
				buffer = buffer.slice( imgEnd + 1 );
			}
		} 
		catch( err ) {
			console.error( "Error inserting chunk:", err );
		}
	}
);

window.contentAPI.onLoadComplete(
	( ) => {
		tinymce.activeEditor.setProgressState( false );
		tinymce.EditorMode.set( 'design' ); // Enable editing
	}
);

const MAX_WIDTH = 800;
const MAX_HEIGHT = 600;
const JPEG_QUALITY = 0.95;
function insertImageFile( file ) {
	const reader = new FileReader( );
	reader.onload = function( e ) {
		const base64data = e.target.result;

		// Create image to get dimensions
		const img = new Image( );
		img.onload = function( ) {
			let { width, height } = img;

			// Keep aspect ratio
			if( width > MAX_WIDTH || height > MAX_HEIGHT ) {
				const aspect = width / height;
				if( width > height ) {
					width = MAX_WIDTH;
					height = Math.round( MAX_WIDTH / aspect );
				} else {
					height = MAX_HEIGHT;
					width = Math.round( MAX_HEIGHT * aspect );
				}
			}
			// Draw resized image
			const canvas = document.createElement( 'canvas' );
			canvas.width = width;
			canvas.height = height;
			const ctx = canvas.getContext( '2d' );
			ctx.drawImage( img, 0, 0, width, height );

			// choose mime type: prefer jpeg (smaller) unless PNG needed
			let mimeType = file.type && file.type.toLowerCase( );
			if( mimeType !== "image/png" && mimeType !== "image/jpeg" ) {
				mimeType = "image/jpeg";
			}
			const quality = ( mimeType === "image/jpeg" ) ? JPEG_QUALITY : 1.0;
			const outDataUrl = canvas.toDataURL( mimeType, quality );

			const safeAlt = ( file?.name || '' ).replace( /"/g, '&quot;' );
			const imgHtml = `<img src="${outDataUrl}" alt="${safeAlt}" width="${width}" height="${height}">`;
			tinymce.activeEditor.insertContent( imgHtml );
		};
		img.src = base64data;
	};
	reader.readAsDataURL( file );
}
