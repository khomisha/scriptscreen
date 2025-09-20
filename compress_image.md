// Compress a dataURL using canvas, returns { dataUrl, width, height }
function compressDataUrl(dataUrl, maxWidth = MAX_DIM.width, maxHeight = MAX_DIM.height, jpegQuality = JPEG_QUALITY) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      try {
        let w = img.naturalWidth || img.width;
        let h = img.naturalHeight || img.height;

        // scale keeping aspect ratio
        if (w > maxWidth || h > maxHeight) {
          const aspect = w / h;
          if (w >= h) {
            w = maxWidth;
            h = Math.round(maxWidth / aspect);
          } else {
            h = maxHeight;
            w = Math.round(maxHeight * aspect);
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, w, h);

        // choose output mime: prefer JPEG for smaller size unless original is PNG and you care about transparency
        const prefPng = /^data:image\/png/i.test(dataUrl);
        const outMime = prefPng ? 'image/png' : 'image/jpeg';
        const quality = outMime === 'image/jpeg' ? jpegQuality : 1.0;

        const outDataUrl = canvas.toDataURL(outMime, quality);
        resolve({ dataUrl: outDataUrl, width: w, height: h });
      } catch (err) {
        reject(err);
      }
    };
    img.onerror = (e) => reject(new Error('Image load error: ' + (e?.message || e)));
    // dataURL is safe to assign as src (no CORS issues)
    img.src = dataUrl;
  });
}

//=================================== deepseek ========================================

function resizeImageBeforeInsertion(base64data, maxWidth, maxHeight, callback) {
  const img = new Image();
  img.onload = function() {
    let width = img.width;
    let height = img.height;
    
    // Calculate new dimensions while maintaining aspect ratio
    if (width > maxWidth) {
      height = (height * maxWidth) / width;
      width = maxWidth;
    }
    
    if (height > maxHeight) {
      width = (width * maxHeight) / height;
      height = maxHeight;
    }
    
    // Create canvas for resizing
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0, width, height);
    
    // Get resized base64
    callback(canvas.toDataURL('image/jpeg', 0.8), width, height);
  };
  img.src = base64data;
}

// Use lower quality for JPEGs
reader.readAsDataURL(blobInfo.blob());
// Then in the onload:
const canvas = document.createElement('canvas');
canvas.width = img.width;
canvas.height = img.height;
const ctx = canvas.getContext('2d');
ctx.drawImage(img, 0, 0);
const compressedBase64 = canvas.toDataURL('image/jpeg', 0.7); // 70% quality

