
// Object references in the card text.
//
// A reference is a span carrying the object type and name, see refs.dart:
//
//     <span class="ref" data-type="role" data-name="Кирилл">Кирилл</span>
//
// The description is not stored in the text, the application pushes the
// descriptions of the project objects here ( see setRefs ) and the reference
// shows the one of its own object on hover. A reference without a description
// shows nothing.
//
// The same file is kept in assets/ for the webview build, keep the two in sync.

( function ( ) {
	const REF_SELECTOR = 'span.ref';

	// { labels: { <type>: <label> }, items: { <type>: { <name>: <description> } } }
	let refs = { labels: {}, items: {} };
	let tip = null;

	/**
	 * Puts the object descriptions of the current project, called by the
	 * application on every project change, see refsAsJson
	 * json the descriptions as json
	 */
	window.setRefs = function( json ) {
		try {
			refs = JSON.parse( json ) || { labels: {}, items: {} };
		}
		catch( err ) {
			console.error( 'Bad references json:', err );
		}
		hideTip( );
	};

	/**
	 * Underlines the references of the loaded text and shows the description
	 * of the one under the cursor
	 * editor the tinymce editor
	 */
	window.initRefs = function( editor ) {
		editor.on(
			'mouseover',
			( e ) => {
				const element = e.target && e.target.closest ? e.target.closest( REF_SELECTOR ) : null;
				if( element ) {
					showTip( editor, element );
				} else {
					hideTip( );
				}
			}
		);
		editor.on( 'mouseout keydown ScrollContent ScrollWindow blur', hideTip );
	};

	/**
	 * Returns the label, the name and the description of the object the
	 * reference points to, null when the object has no description
	 */
	function describe( element ) {
		const type = element.getAttribute( 'data-type' ) || '';
		const name = element.getAttribute( 'data-name' ) || element.textContent;
		const items = ( refs.items || {} )[ type ];
		const text = items ? items[ name ] : '';
		if( !text ) {
			return null;
		}
		return { label: ( refs.labels || {} )[ type ] || type, name: name, text: text };
	}

	/**
	 * Shows the description over the reference. The text is edited within an
	 * iframe, the tip belongs to the window around it, so the content itself
	 * is never touched.
	 */
	function showTip( editor, element ) {
		const found = describe( element );
		if( !found ) {
			hideTip( );
			return;
		}
		const node = tipElement( );
		node.textContent = '';
		const head = document.createElement( 'div' );
		head.setAttribute( 'style', 'font-weight: bold; margin-bottom: 2px;' );
		head.textContent = found.label + ': ' + found.name;
		const body = document.createElement( 'div' );
		body.textContent = found.text;
		node.appendChild( head );
		node.appendChild( body );
		node.style.display = 'block';
		const frame = editor.iframeElement ? editor.iframeElement.getBoundingClientRect( ) : { left: 0, top: 0 };
		const box = element.getBoundingClientRect( );
		const left = Math.min(
			Math.max( 4, frame.left + box.left ),
			Math.max( 4, window.innerWidth - node.offsetWidth - 4 )
		);
		const below = frame.top + box.bottom + 6;
		const top = below + node.offsetHeight > window.innerHeight
			? frame.top + box.top - node.offsetHeight - 6
			: below;
		node.style.left = left + 'px';
		node.style.top = Math.max( 4, top ) + 'px';
	}

	/**
	 * Hides the description
	 */
	function hideTip( ) {
		if( tip ) {
			tip.style.display = 'none';
		}
	}

	/**
	 * Returns the tip element, creating it on the first call
	 */
	function tipElement( ) {
		if( tip ) {
			return tip;
		}
		tip = document.createElement( 'div' );
		tip.setAttribute(
			'style',
			'position: fixed; z-index: 10000; display: none; max-width: 420px;'
			+ ' padding: 6px 10px; border: 1px solid #999999; border-radius: 4px;'
			+ ' background: #ffffe1; color: #222222; font: 12px/1.4 Arial, sans-serif;'
			+ ' box-shadow: 0 2px 6px rgba( 0, 0, 0, 0.3 ); pointer-events: none;'
		);
		document.body.appendChild( tip );
		return tip;
	}
} )( );
