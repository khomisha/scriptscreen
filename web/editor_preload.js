const { contextBridge, ipcRenderer } = require( 'electron' );

contextBridge.exposeInMainWorld(
	'contentAPI', 
	{
        onChunkRequest: ( callback ) => ipcRenderer.on( 'request-chunk', callback ),
        sendChunk: ( chunk ) => ipcRenderer.send( 'save-chunk', chunk ),
        onLoadChunk: ( callback ) => ipcRenderer.on( 'load-chunk', ( _, chunk ) => callback( chunk ) ),
        onBeginLoading: ( callback ) => ipcRenderer.on( 'begin-loading', callback ),
        onLoadComplete: ( callback ) => ipcRenderer.on( 'load-complete', callback )
    }
);
