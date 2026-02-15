// The faster whisper must be installed
// pip install -U whisper-ctranslate2

const { execFile } = require( 'child_process' );
const fs = require( 'node:fs' );
const path = require( 'path' );
const os = require( 'os' );

class WhisperCLI {
    constructor( ) {
        this.isProcessing = false;
    }

    async transcribe( audioPath, model = 'small', language = 'ru') {
        if( this.isProcessing ) {
            throw new Error( 'Another transcription is in progress' );
        }

        this.isProcessing = true;

        return new Promise(
            ( resolve, reject ) => {
                // Create temporary output file
                const tempDir = os.tmpdir( );
                const baseName = path.basename( audioPath, path.extname( audioPath ) );
                const outputPath = path.join( tempDir, `${baseName}` );

                console.log( `Starting Whisper transcription: ${audioPath}` );
                console.log( `Model: ${model}, Language: ${language}` );
                console.log( `Output: ${outputPath}.srt` );

                const args = [
                    audioPath,
                    '--model', model,
                    '--language', language,
                    '--output_dir', tempDir,
                    '--output_format', 'srt',
                    '--device', 'cpu',
                    '--threads', '6',
                    //'--model_dir', '~/.cache/huggingface/'
                ];

                // Add optional parameters for better quality
                if( model !== 'turbo' ) {
                    args.push( '--beam_size', '10' );
                    args.push( '--best_of', '10' );
                    args.push( '--length_penalty', '1.0' );
                }

                execFile( 
                    'whisper-ctranslate2', 
                    args, 
                    ( error, stdout, stderr ) => {
                        this.isProcessing = false;

                        if( error ) {
                            console.error( 'Whisper error:', error );
                            // Clean up any partial files
                            this.cleanupFiles( outputPath );
                            reject( new Error( `Whisper failed: ${stderr || error.message}` ) );
                            return;
                        }

                        console.log( 'Whisper stdout:', stdout );
                        if( stderr ) {
                            console.log( 'Whisper stderr:', stderr );
                        }

                        // Read the result file
                        const resultFile = outputPath + '.srt';
                        fs.readFile(
                            resultFile, 
                            'utf8', 
                            ( readError, text ) => {
                                // Clean up temp files regardless of read result
                                this.cleanupFiles( outputPath );

                                if( readError ) {
                                    reject( new Error( `Failed to read result file: ${readError.message}` ) );
                                    return;
                                }

                                resolve(
                                    { success: true, text: text.trim( ), model: model, language: language }
                                );
                            }
                        );
                    }
                );
            }
        );
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

    // Check if whisper command is available
    async checkWhisperInstallation( ) {
        return new Promise(
            ( resolve ) => {
                execFile( 
                    'whisper', 
                    ['--help'], 
                    ( error ) => { resolve( !error ); }
                );
            }
        );
    }

    getAvailableModels( ) {
        return [ 'tiny', 'base', 'small', 'medium', 'large', 'large-v2', 'large-v3' ];
    }

    stop( ) {
        if( this.process ) {
            console.log( 'Terminating Whisper process...' );
            this.process.kill( 'SIGTERM' );
            this.process = null;
        }
    }
}

module.exports = WhisperCLI;