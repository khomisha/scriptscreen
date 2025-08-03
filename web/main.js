// main.js

// Modules to control application life and create native browser window
const { app, BrowserWindow, ipcMain } = require( 'electron' )
const path = require( 'node:path' )
const fs = require( 'fs/promises' );
const fss = require('fs')

// app.commandLine.appendSwitch( 'enable-logging' )
// app.commandLine.appendSwitch( 'log-level', '0' )

// Constants
const CMD_CREATE = "cmd_create";
const CMD_LOAD = "cmd_load";
const CMD_SAVE = "cmd_save";
const CMD_EXIT = "cmd_exit";
const SUCCESS = 0;
const FAILURE = 1;
const ERR_MSG = 'error_message';
const ERROR = 'error';
const STACK = 'stack_trace';
const READ = 0;
const WRITE = 1;
const APPEND = 2;
const WRITE_ONLY = 3;
const WRITE_ONLY_APPEND = 4;

let browser = null;

const createWindow = ( ) => {
    // Create the main window.
    const mainWindow = new BrowserWindow( 
        {
            width: 800,
            height: 600,
            webPreferences: { 
                nodeIntegration: true, 
                contextIsolation: true,
                preload: path.join( __dirname, 'preload.js' ) 
            }
        }
    )

    // Create the secondary window
    browser = new BrowserWindow(
        {
            width: 800,
            height: 600,
            x: 100,
            y: 100,
            show: false,
            closable: false,
            webPreferences: { 
                nodeIntegration: true, 
                contextIsolation: true,
                preload: path.join( __dirname, 'editor_preload.js' ) 
            },
            //titleBarStyle: 'hidden'
        }
    )

    mainWindow.setMenuBarVisibility( false );
    //browser.setMenuBarVisibility( false );
    
    mainWindow.on( "closed", 
        ( ) => {
            browser.destroy( );
        }
    );

    browser.on( "close", ( event ) => { event.preventDefault( ) } );

    // and load the index.html of the app.
    mainWindow.loadFile( 'index.html' );

    // Open the DevTools.
    mainWindow.webContents.openDevTools( );
    browser.webContents.openDevTools( );

    browser.loadFile( 'editor.html' );
}

ipcMain.handle( 
	'read-file', 
	async ( _, fileName ) => {
		try {
			return await fs.readFile( fileName, 'utf-8' );
		} catch( err ) {
            throw new Error( `File read failed: ${err.message}\n${err.stack}` );
		}
	}
);

ipcMain.handle( 
	'process', 
	async ( _, data ) => {
		try {
            return await process( data );   
		} catch( err ) {
            throw new Error( `Process data failed: ${err.message}\n${err.stack}` );
		}
	}
);

let readStream = null;
ipcMain.handle( 
    'load-content', 
    async ( _, fileName ) => {
        try {
            const stats = await fs.stat( fileName );
            const fileSize = stats.size;
            const CHUNK_SIZE = fileSize > 100 * 1024 * 1024 ? 1024 * 1024 : 64 * 1024; // 1MB or 64KB
             browser.webContents.send( 'begin-loading' );
            // Create read stream
            readStream = fss.createReadStream( fileName, { encoding: 'utf8', highWaterMark: CHUNK_SIZE } );
            // Stream chunks to renderer
            for await ( const chunk of readStream ) {
                browser.webContents.send( 'load-chunk', chunk );
            }
            console.log( 'send load-complete' );
            browser.webContents.send( 'load-complete' );
            return "success";
        } 
        catch( err ) {
            throw new Error( `Save content init failed: ${err.message}\n${err.stack}` );
        }
    }
);

let saveStream = null;
ipcMain.handle( 
    'save-content', 
    async ( _, fileName ) => {
        try {
            // Create write stream
            saveStream = fss.createWriteStream( fileName );
            // Start the process by requesting first chunk
            browser.webContents.send( 'request-chunk' );
            return "success";
        } 
        catch( err ) {
            throw new Error( `Save content init failed: ${err.message}\n${err.stack}` );
        }
    }
);

// Handle chunk data from renderer
ipcMain.on(
    'save-chunk', 
    ( _, chunk ) => {
        try{
            if( !saveStream ) return;

            // End of stream signal
            if( chunk === null ) {
                saveStream.end( );
                saveStream = null;
                console.log( 'Save completed successfully' );
                return;
            }

            // Write chunk to file
            if( !saveStream.write( chunk ) ) {
                // Pause if buffer is full
                saveStream.once( 'drain', ( ) => browser.webContents.send( 'request-chunk' ) );
            } else {
                // Immediately request next chunk
                browser.webContents.send( 'request-chunk' );
            }
        }
        catch( err ) {
            console.error( 'Save content chunks failed:', err );
        }
    }
);

ipcMain.handle( 
	'clear-content', 
	async ( _, arg ) => {
		try {
			return await browser.webContents.executeJavaScript( 'tinymce.activeEditor.resetContent()' );
		} catch( err ) {
            throw new Error( `Clear content failed: ${err.message}\n${err.stack}` );
		}
	}
);

ipcMain.on( 
    'user-dir', 
    ( event, arg ) => {
        event.returnValue = app.getPath( 'home' );
    }
);

ipcMain.on( 
    'app-dir', 
    ( event, arg ) => {
        event.returnValue = app.getAppPath( );
    }
);

ipcMain.on( 
    'exists', 
    ( event, path ) => {
        event.returnValue = fss.existsSync( path );
    }
);

ipcMain.handle( 
    'mkdir', 
    async ( _, path ) => {
		try {
			return await fs.mkdir( path, { recursive: true } );
		} catch( error ) {
			throw new Error( `Make dir failed: ${err.message}\n${err.stack}` );
		}
    }
);

ipcMain.handle( 
    'delete', 
    async ( _, path ) => {
		try {
			await fs.rm( path );
            return "success";
		} catch( error ) {
			throw new Error( `Make dir failed: ${err.message}\n${err.stack}` );
		}
    }
);

ipcMain.handle( 
    'change-visibility', 
    async ( _, arg ) => {
		try {
            var visible = browser.isVisible( )
            if( visible ) {
			    browser.hide( );
            } else {
                browser.show( );
            }
            return visible
		} catch( err ) {
            throw new Error( `Change visibility failed: ${err.message}\n${err.stack}` );
		}
    }
);

ipcMain.handle( 
    'write-file', 
    async ( _, fileName, content, mode ) => {
		try {
            await fs.mkdir( path.dirname( fileName ), { recursive: true } );
            if( mode == WRITE ) {
                fs.writeFile( fileName, content, 'utf-8' );
            }
            if( mode == APPEND ) {
                 fs.appendFile( fileName, content, 'utf-8' );
            }
            return "success"
		} catch( err ) {
            throw new Error( `File write failed: ${err.message}\n${err.stack}` );
		}
    }
);

ipcMain.handle( 
    'set-content', 
    async ( _, content ) => {
		try {
            var script = 'tinymce.activeEditor.setContent(' + content + ')';
            await browser.webContents.executeJavaScript( script );
            return "success"
		} catch( err ) {
            throw new Error( `Set content failed: ${err.message}\n${err.stack}` );
		}
    }
);

ipcMain.handle( 
    'copy-dir', 
    async ( _, src, dest ) => {
		try {
            return await fs.cp( src, dest, {recursive: true} );
		} catch( err ) {
            throw new Error( `Copy dir failed: ${err.message}\n${err.stack}` );
		}
    }
);

async function process( data ) {
    var map = new Map( Object.entries( data ) );
    const command = map.get( 'command' );
    try {
        switch( command ) {
            case CMD_CREATE:
                await _create( map );
                break;
            case CMD_LOAD:
                await _load( map );
                break;
            case CMD_SAVE:
                _save( map );
                break;
            case CMD_EXIT:
                _exit( map );
                break;
            default:
                map.set( 'result', FAILURE );
                map.set( ERR_MSG, `No such method ${command}` );
        }
    } catch( e ) {
        // Error handling
        map.set( 'result', FAILURE );
        map.set( ERR_MSG, `${command} ${e.message}` );
        map.set( ERROR, e );
        map.set( STACK, e.STACK );
    }
    return Object.fromEntries( map.entries( ) );
};

// Async sleep helper
function sleep( ms ) {
    return new Promise( resolve => setTimeout( resolve, ms ) );
}

/**
 * Creates empty project data
 * map the object
 */
async function _create( map ) {
    var data4Save =  map.get( 'for_save' );
    if( data4Save != null ) {
        _save( data4Save );
    }
    var fileName = path.join( app.getAppPath( ), 'assets', 'assets', 'cfg', 'empty.json' );
    var data = await fs.readFile( fileName, 'utf-8' );
    map.set( 'data', data ); 
    map.set( 'result', SUCCESS ); 
}

/**
 * Loads project data from specified file
 * map the object to save
 */
async function _load( map ) {
    var data4Save =  map.get( 'for_save' );
    if( data4Save != null ) {
        _save( data4Save );
    }
    var data = await fs.readFile( map.get( 'filename' ), 'utf-8' );
    map.set( 'data', data ); 
    map.set( 'result', SUCCESS ); 
}

/**
 * Saves project data to the specified file
 * map the object to save
 */
async function _save( map ) {
    await fs.writeFile( map.get( 'filename' ), map.get( 'data' ), 'utf-8' );
    map.set( 'result', SUCCESS ); 
}

/**
 * Application exit
 * map the object to save
 */
function _exit( map ) {
    _save( map );
    map.set( 'result', SUCCESS ); 
}
  
// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady( ).then( 
    ( ) => {
        createWindow( )

        app.on( 
            'activate', 
            ( ) => {
                // On macOS it's common to re-create a window in the app when the
                // dock icon is clicked and there are no other windows open.
                if( BrowserWindow.getAllWindows( ).length === 0 ) createWindow( )
            }
        )
    }
)

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on( 'window-all-closed', ( ) => { if( process.platform !== 'darwin' ) app.quit( ) } )

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
