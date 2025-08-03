tinymce.init({
	selector: 'textarea#mytextarea',
	height: 500,
	plugins: [
	  'advlist', 'lists',
	  'searchreplace', 'visualblocks', 'charmap', 'fullscreen',
	  'insertdatetime', 'help', 'wordcount', 'code'
	],
	toolbar: 'undo redo | fontfamily fontsize |' +
	  'bold italic underline | alignleft aligncenter alignright alignjustify |' +
	  'bullist numlist outdent indent | charmap code | searchreplace | help',
	init_instance_callback: function(editor) {
	  editor.execCommand('mceFullScreen');
	},
	content_style: 'div { font-family:Courier New,Arial,sans-serif; font-size:12pt; }',
	promotion: false,
	menubar: false,
	forced_root_block : 'div',
	contextmenu: false,
	// example <div class="nonedit">You cannot edit this</div>
	noneditable_class: 'nonedit'
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
		console.log( 'onBeginLoading' );
		progress = 0;
		tinymce.activeEditor.setProgressState( true );
		tinymce.activeEditor.setContent(''); // Clear editor
		tinymce.EditorMode.set( 'readonly' ); // Prevent editing during load
	}
);

window.contentAPI.onLoadChunk(
	( chunk ) => {
		try {
			// Insert chunk at current cursor position
			tinymce.activeEditor.insertContent( chunk );
			progress += chunk.length;
			//tinymce.activeEditor.setProgressState( true, Math.min( 100, progress / 1000000 * 100 ) );
		} 
		catch( err ) {
			console.error( 'Error inserting chunk:', err );
		}
	}
);

window.contentAPI.onLoadComplete(
	( ) => {
		console.log( 'onLoadComplete' );
		tinymce.activeEditor.setProgressState( false );
		tinymce.EditorMode.set( 'design' ); // Enable editing
	}
);



