const { execFile, spawn } = require( 'child_process' );
const fs = require( 'node:fs' );
const path = require( 'path' );
const os = require( 'os' );

class WhisperCLI {
    constructor( ) {
        this.isProcessing = false;
        this.liveProcess = null;
    }

    convertToWav( inputPath ) {
        const tempDir  = os.tmpdir( );
        const baseName = path.basename( inputPath, path.extname( inputPath ) );
        const wavPath  = path.join( tempDir, `${baseName}_whisper.wav` );

        return new Promise( ( resolve, reject ) => {
            execFile(
                'ffmpeg',
                [ '-y', '-i', inputPath, '-ar', '16000', '-ac', '1', '-c:a', 'pcm_s16le', wavPath ],
                ( error, _stdout, stderr ) => {
                    if( error ) {
                        reject( new Error( `ffmpeg conversion failed: ${stderr || error.message}` ) );
                        return;
                    }
                    resolve( wavPath );
                }
            );
        } );
    }

    async transcribe( audioPath, model = 'small', language = 'ru' ) {
        if( this.isProcessing ) {
            throw new Error( 'Another transcription is in progress' );
        }

        this.isProcessing = true;

        let wavPath = null;

        try {
            const ext = path.extname( audioPath ).toLowerCase( );
            if( ext !== '.wav' ) {
                console.log( `Converting ${ext} to WAV for whisper.cpp...` );
                wavPath = await this.convertToWav( audioPath );
            }

            const inputPath  = wavPath || audioPath;
            const homeDir    = os.homedir( );
            const binary     = path.join( homeDir, 'whisper.cpp', 'build', 'bin', 'whisper-cli' );
            const modelPath  = path.join( homeDir, 'whisper.cpp', 'models', `ggml-${model}.bin` );
            const tempDir    = os.tmpdir( );
            const baseName   = path.basename( audioPath, path.extname( audioPath ) );
            const outputPath = path.join( tempDir, baseName );

            console.log( `Starting Whisper transcription: ${audioPath}` );
            console.log( `Model: ${model}, Language: ${language}` );
            console.log( `Output: ${outputPath}.txt` );

            const args = [
                '-f', inputPath,
                '-m', modelPath,
                '-l', language,
                '-t', '6',
                '-of', outputPath,
                '--output-txt',
            ];

            if( !model.includes( 'turbo' ) ) {
                args.push( '-bs', '8' );
            }

            return await new Promise(
                ( resolve, reject ) => {
                    execFile(
                        binary,
                        args,
                        ( error, stdout, stderr ) => {
                            if( error ) {
                                console.error( 'Whisper error:', error );
                                this.cleanupFiles( outputPath );
                                reject( new Error( `Whisper failed: ${stderr || error.message}` ) );
                                return;
                            }

                            console.log( 'Whisper stdout:', stdout );
                            if( stderr ) {
                                console.log( 'Whisper stderr:', stderr );
                            }

                            const resultFile = outputPath + '.txt';
                            fs.readFile(
                                resultFile,
                                'utf8',
                                ( readError, text ) => {
                                    this.cleanupFiles( outputPath );

                                    if( readError ) {
                                        reject( new Error( `Failed to read result file: ${readError.message}` ) );
                                        return;
                                    }

                                    resolve(
                                        {
                                            success: true,
                                            text: this.escapeHTML( text ),
                                            model: model,
                                            language: language
                                        }
                                    );
                                }
                            );
                        }
                    );
                }
            );
        }
        finally {
            this.isProcessing = false;
            if( wavPath ) {
                try { fs.unlinkSync( wavPath ); } catch( _ ) { }
            }
        }
    }

    cleanupFiles( basePath ) {
        const extensions = [ '.txt', '.json', '.srt', '.vtt', '.tsv' ];
        extensions.forEach( 
            ext => {
                const filePath = basePath + ext;
                if( fs.existsSync( filePath ) ) {
                    try {
                        fs.unlinkSync( filePath );
                    } 
                    catch( e ) {
                        console.warn( 'Could not delete temp file:', filePath );
                    }
                }
            }
        );
    }

    async checkWhisperInstallation( ) {
        const binary = path.join( os.homedir( ), 'whisper.cpp', 'build', 'bin', 'whisper-cli' );
        return new Promise(
            ( resolve ) => {
                execFile(
                    binary,
                    ['--help'],
                    ( error ) => { resolve( !error ); }
                );
            }
        );
    }

    getAvailableModels( ) {
        return [ 'tiny', 'base', 'small', 'medium', 'large', 'large-v2', 'large-v3' ];
    }

    startLive( model, language, onChunk, onError, onStop ) {
        if( this.liveProcess ) {
            throw new Error( 'Live transcription already running' );
        }

        const homeDir = os.homedir( );
        const binary   = path.join( homeDir, 'whisper.cpp', 'build', 'bin', 'whisper-stream' );
        const modelPath = path.join( homeDir, 'whisper.cpp', 'models', `ggml-${model}.bin` );

        const args = [
            '-m', modelPath,
            '-l', language,
            '-t', '6',
            '--step', '0',          // step=0 activates VAD mode: transcribes on silence, outputs ### Transcription N START/END markers
            '--vad-thold', '0.7',   // VAD sensitivity threshold
            '-bs', '1',             // greedy decoding — fastest on CPU
        ];

        console.log( `Starting live transcription (whisper.cpp): model=${model}, language=${language}` );

        // VAD mode output format (stdout):
        //   ### Transcription N START | t0 = X ms | t1 = Y ms
        //   <empty line>
        //    transcribed text
        //   <empty line>
        //   ### Transcription N END
        let buffer = '';
        let inSegment = false;
        let segmentText = '';

        this.liveProcess = spawn( binary, args );

        this.liveProcess.stdout.on( 'data', ( data ) => {
            buffer += data.toString( );
            const lines = buffer.split( '\n' );
            buffer = lines.pop( ); // keep incomplete last line

            for( const line of lines ) {
                if( line.includes( '### Transcription' ) && line.includes( 'START' ) ) {
                    inSegment = true;
                    segmentText = '';
                } else if( line.includes( '### Transcription' ) && line.includes( 'END' ) ) {
                    const text = segmentText.trim( );
                    if( text ) onChunk( text );
                    inSegment = false;
                    segmentText = '';
                } else if( inSegment ) {
                    // strip timestamp prefix: "[00:00:00.000 --> 00:00:02.000]  "
                    const clean = line.trim( ).replace( /^\[\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}\]\s*/, '' );
                    if( clean ) segmentText += clean + ' ';
                }
            }
        } );

        this.liveProcess.stderr.on( 'data', ( data ) => {
            console.log( 'whisper-stream:', data.toString( ) );
        } );

        this.liveProcess.on( 'error', ( error ) => {
            console.error( 'Live transcription error:', error );
            this.liveProcess = null;
            if( onError ) onError( error.message );
        } );

        this.liveProcess.on( 'close', ( code ) => {
            console.log( `Live transcription stopped (code: ${code})` );
            this.liveProcess = null;
            if( onStop ) onStop( );
        } );
    }

    stopLive( ) {
        if( this.liveProcess ) {
            console.log( 'Stopping live transcription...' );
            this.liveProcess.kill( 'SIGTERM' );
            this.liveProcess = null;
        }
    }

    isLiveRunning( ) {
        return this.liveProcess !== null;
    }

    stop( ) {
        if( this.process ) {
            console.log( 'Terminating Whisper process...' );
            this.process.kill( 'SIGTERM' );
            this.process = null;
        }
        this.stopLive( );
    }

    escapeHTML( str ) {
        return str
            .replace( /\r\n/g, '\n')
            .replace( /\n\n/g, '\n' )
            .replace( /\n/g, '<br>' );
    }
}

module.exports = WhisperCLI;