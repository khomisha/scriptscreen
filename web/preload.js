const { contextBridge, ipcRenderer } = require( 'electron' );

contextBridge.exposeInMainWorld(
	'electronAPI', 
	{
		readFile: ( path ) => ipcRenderer.invoke( 'read-file', path ),
		writeFile: ( path, content, mode ) => ipcRenderer.invoke( 'write-file', path, content, mode ),
		getUserDir: ( ) => ipcRenderer.sendSync( 'user-dir' ),
		getAppDir: ( ) => ipcRenderer.sendSync( 'app-dir' ),
		isExist: ( ) => ipcRenderer.sendSync( 'exists', path ),
		sendMessage: ( data ) => ipcRenderer.invoke( 'process', data ),
		copyDir: ( src, dest ) => ipcRenderer.invoke( 'copy-dir', src, dest ),
		mkDir: ( path ) => ipcRenderer.invoke( 'mkdir', path ),
		delete: ( path ) => ipcRenderer.invoke( 'delete', path )
	}
);

contextBridge.exposeInMainWorld(
	'appElectronAPI', 
	{
		changeVisibility: ( ) => ipcRenderer.invoke( 'change-visibility' ),
        load: ( ) => ipcRenderer.invoke( 'load-content', fileName ),
		save: ( content ) => ipcRenderer.invoke( 'save-content', fileName ),
		clear: ( ) => ipcRenderer.invoke( 'clear-content' ),
	}
);
