const { contextBridge, ipcRenderer } = require( 'electron' );

contextBridge.exposeInMainWorld(
	'contentAPI', 
	{
        onChunkRequest: ( callback ) => ipcRenderer.on( 'request-chunk', callback ),
        sendChunk: ( chunk ) => ipcRenderer.send( 'save-chunk', chunk ),
        skipSave: ( ) => ipcRenderer.send( 'skip-save' ),
        onLoadChunk: ( callback ) => ipcRenderer.on( 'load-chunk', ( _, chunk ) => callback( chunk ) ),
        onBeginLoading: ( callback ) => ipcRenderer.on( 'begin-loading', callback ),
        onLoadComplete: ( callback ) => ipcRenderer.on( 'load-complete', ( _, dirty ) => callback( dirty ) ),
        onLiveTranscribeChunk: ( callback ) => ipcRenderer.on( 'live-transcribe-chunk', ( _, text ) => callback( text ) ),
        onSetRefs: ( callback ) => ipcRenderer.on( 'set-refs', ( _, json ) => callback( json ) ),
        getRefs: ( ) => ipcRenderer.invoke( 'get-refs' )
    }
);
