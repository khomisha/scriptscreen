const { contextBridge, ipcRenderer } = require( 'electron' );

contextBridge.exposeInMainWorld(
	'electronAPI', 
	{
		readFile: ( path ) => ipcRenderer.invoke( 'read-file', path ),
		writeFile: ( path, content, mode ) => ipcRenderer.invoke( 'write-file', path, content, mode ),
		getUserDir: ( ) => ipcRenderer.sendSync( 'user-dir' ),
		getAppDir: ( ) => ipcRenderer.sendSync( 'app-dir' ),
		isExist: ( path ) => ipcRenderer.sendSync( 'exists', path ),
		sendMessage: ( data ) => ipcRenderer.invoke( 'process', data ),
		copyDir: ( src, dest ) => ipcRenderer.invoke( 'copy-dir', src, dest ),
		mkDir: ( path ) => ipcRenderer.invoke( 'mkdir', path ),
		changeVisibility: ( ) => ipcRenderer.invoke( 'change-visibility' ),
		delete: ( path ) => ipcRenderer.invoke( 'delete', path ),
		pickupFile: ( options ) => ipcRenderer.invoke( 'pickup-file', options )	
	}
);

contextBridge.exposeInMainWorld(
	'appElectronAPI', 
	{
        load: ( fileName ) => ipcRenderer.invoke( 'load-content', fileName ),
		save: ( fileName ) => ipcRenderer.invoke( 'save-content', fileName ),
		clear: ( ) => ipcRenderer.invoke( 'clear-content' ),
		convert2PDF: ( headers, htmlFiles, pdfPath ) => ipcRenderer.invoke( 'convert-html-to-pdf', headers, htmlFiles, pdfPath ),
		transcribe: ( path, model, lang ) => ipcRenderer.invoke( 'transcribe-audio', path, model, lang ),
	}
);
