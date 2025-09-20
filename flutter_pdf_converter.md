import 'dart:io';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';

Future<void> main() async {
  final files = ['file1.html', 'file2.html'];
  final buffer = StringBuffer();

  for (var path in files) {
    buffer.writeln(await File(path).readAsString());
    buffer.writeln('<hr>'); // optional separator
  }

  final pdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
    buffer.toString(),
    Directory.systemTemp.path,
    "merged",
  );

  print("Saved at: ${pdfFile.path}");
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';

class HtmlToPdfExample extends StatefulWidget {
  @override
  _HtmlToPdfExampleState createState() => _HtmlToPdfExampleState();
}

class _HtmlToPdfExampleState extends State<HtmlToPdfExample> {
  Future<void> _generatePdf() async {
    final htmlContent = """
      <h1>My Title</h1>
      <p>This is <b>bold</b>, <i>italic</i>, and an image:</p>
      <img src="https://via.placeholder.com/150">
    """;

    final outputDir = await Directory.systemTemp.createTemp();
    final pdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
      htmlContent,
      outputDir.path,
      "example",
    );

    print("PDF saved at: ${pdfFile.path}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Generate PDF"),
          onPressed: _generatePdf,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintPreviewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdfPreview(
        build: (format) => _generatePdf(format),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text("My Title", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Paragraph(text: "This is bold/italic manually styled."),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}

Good question 👍
With **Electron.js**, you have a built-in way to render HTML and export it as PDF, because under the hood Electron uses **Chromium**.

The trick is:

1. Load each HTML file in a hidden/offscreen `BrowserWindow`.
2. Use [`webContents.printToPDF`](https://www.electronjs.org/docs/latest/api/web-contents#contentsprinttopdfoptions) to generate a PDF.
3. Concatenate the results into one final PDF.

---

## 🔹 Example: Merge multiple HTML files into one PDF

You’ll need a **PDF merger library** because `printToPDF` produces one PDF per file. A popular one is [`pdf-lib`](https://github.com/Hopding/pdf-lib).

```js
const { app, BrowserWindow } = require("electron");
const path = require("path");
const fs = require("fs");
const { PDFDocument } = require("pdf-lib");

async function createMergedPdf(htmlFiles, outputPath) {
  const pdfDocs = [];

  for (const file of htmlFiles) {
    const win = new BrowserWindow({
      show: false, // don't show window
      webPreferences: {
        offscreen: true,
      },
    });

    await win.loadFile(file);

    const pdfBuffer = await win.webContents.printToPDF({
      landscape: false,
      printBackground: true,
    });

    pdfDocs.push(pdfBuffer);
    
    win.destroy();
  }

  // Merge all PDFs using pdf-lib
  const mergedPdf = await PDFDocument.create();

  for (const pdfBytes of pdfDocs) {
    const doc = await PDFDocument.load(pdfBytes);
    const copiedPages = await mergedPdf.copyPages(doc, doc.getPageIndices());
    copiedPages.forEach((p) => mergedPdf.addPage(p));
  }

  const mergedBytes = await mergedPdf.save();
  fs.writeFileSync(outputPath, mergedBytes);

  console.log("Merged PDF saved at:", outputPath);
}

app.whenReady().then(async () => {
  const htmlFiles = [
    path.join(__dirname, "file1.html"),
    path.join(__dirname, "file2.html"),
    path.join(__dirname, "file3.html"),
  ];

  await createMergedPdf(htmlFiles, path.join(__dirname, "output.pdf"));
  app.quit();
});
```

---

## 🔹 How it works

* `BrowserWindow` loads each HTML file.
* `webContents.printToPDF()` generates a PDF buffer.
* `pdf-lib` merges all those PDFs into one.
* Saves final `output.pdf`.

---

👉 This gives you **full HTML + CSS fidelity** (since Chromium does the rendering) and supports everything your HTML can render in a browser — including `<h1>`, `<h2>`, `<p>`, `<b>/<strong>`, `<i>/<em>`, `<img>`, even flexbox/grid layouts.

---

Do you want me to also show a **variant that merges the HTML files first** (concatenate them into a single HTML page, then export directly to PDF) instead of merging PDFs afterward?


Exactly ✅ — you don’t need to create/destroy a `BrowserWindow` for each HTML file. You can reuse one hidden `BrowserWindow`, load each HTML, inject your **title + description**, then export to PDF.

Here’s a clean pattern:

---

## 🔹 Example: Insert Title & Description before PDF Export

```js
const { app, BrowserWindow } = require("electron");
const path = require("path");
const fs = require("fs");
const { PDFDocument } = require("pdf-lib");

async function exportHtmlToPdf(win, filePath, title, description) {
  await win.loadFile(filePath);

  // Inject title + description at top of body
  await win.webContents.executeJavaScript(`
    const wrapper = document.createElement("div");
    wrapper.style.marginBottom = "20px";

    const h1 = document.createElement("h1");
    h1.innerText = ${JSON.stringify(title)};
    h1.style.fontFamily = "Arial, sans-serif";
    h1.style.fontSize = "28px";
    h1.style.marginBottom = "10px";

    const p = document.createElement("p");
    p.innerText = ${JSON.stringify(description)};
    p.style.fontFamily = "Arial, sans-serif";
    p.style.fontSize = "14px";
    p.style.color = "#555";

    wrapper.appendChild(h1);
    wrapper.appendChild(p);

    document.body.insertBefore(wrapper, document.body.firstChild);
  `);

  return await win.webContents.printToPDF({
    landscape: false,
    printBackground: true,
  });
}

async function createMergedPdf(htmlFiles, outputPath) {
  const win = new BrowserWindow({
    show: false,
    webPreferences: { offscreen: true },
  });

  const pdfDocs = [];

  for (const file of htmlFiles) {
    const fileName = path.basename(file, ".html");
    const title = `Report for ${fileName}`;
    const description = `This section describes the content of ${fileName}.`;

    const pdfBuffer = await exportHtmlToPdf(win, file, title, description);
    pdfDocs.push(pdfBuffer);
  }

  // Merge PDFs
  const mergedPdf = await PDFDocument.create();
  for (const pdfBytes of pdfDocs) {
    const doc = await PDFDocument.load(pdfBytes);
    const pages = await mergedPdf.copyPages(doc, doc.getPageIndices());
    pages.forEach((p) => mergedPdf.addPage(p));
  }

  fs.writeFileSync(outputPath, await mergedPdf.save());
  console.log("Merged PDF saved at:", outputPath);

  win.destroy();
}

app.whenReady().then(async () => {
  const htmlFiles = [
    path.join(__dirname, "file1.html"),
    path.join(__dirname, "file2.html"),
  ];

  await createMergedPdf(htmlFiles, path.join(__dirname, "output.pdf"));
  app.quit();
});
```

---

## 🔹 What happens here

1. Reuse **one hidden `BrowserWindow`**.
2. For each HTML file:

   * Load the file.
   * Run `executeJavaScript` to **insert a programmatically formatted `<h1>` + `<p>`** at the top.
   * Call `printToPDF()`.
3. Merge all PDFs into one.

---

👉 Would you like me to also show how to insert a **page break after each HTML file** (so they don’t flow into each other in the merged PDF)?

Got it ✅ — you don’t want to hard-wire `executeJavaScript` with inline strings every time.
Instead, we can prepare a **template JS snippet** (like a mini HTML injection template), and just substitute title/description before running it.

---

## 🔹 Step 1. Make a reusable injection template

Create a separate file `inject-template.js`:

```js
(() => {
  const wrapper = document.createElement("div");
  wrapper.style.marginBottom = "20px";

  const h1 = document.createElement("h1");
  h1.innerText = "__TITLE__";
  h1.style.fontFamily = "Arial, sans-serif";
  h1.style.fontSize = "28px";
  h1.style.marginBottom = "10px";

  const p = document.createElement("p");
  p.innerText = "__DESCRIPTION__";
  p.style.fontFamily = "Arial, sans-serif";
  p.style.fontSize = "14px";
  p.style.color = "#555";

  wrapper.appendChild(h1);
  wrapper.appendChild(p);

  document.body.insertBefore(wrapper, document.body.firstChild);
})();
```

Here `__TITLE__` and `__DESCRIPTION__` are placeholders.

---

## 🔹 Step 2. Load and substitute before injecting

In your main Electron code:

```js
const { app, BrowserWindow } = require("electron");
const path = require("path");
const fs = require("fs");
const { PDFDocument } = require("pdf-lib");

const injectionTemplate = fs.readFileSync(
  path.join(__dirname, "inject-template.js"),
  "utf-8"
);

async function exportHtmlToPdf(win, filePath, title, description) {
  await win.loadFile(filePath);

  // Substitute values into template
  const script = injectionTemplate
    .replace("__TITLE__", title.replace(/"/g, '\\"'))
    .replace("__DESCRIPTION__", description.replace(/"/g, '\\"'));

  await win.webContents.executeJavaScript(script);

  return await win.webContents.printToPDF({
    landscape: false,
    printBackground: true,
  });
}

async function createMergedPdf(htmlFiles, outputPath) {
  const win = new BrowserWindow({
    show: false,
    webPreferences: { offscreen: true },
  });

  const pdfDocs = [];

  for (const file of htmlFiles) {
    const fileName = path.basename(file, ".html");
    const title = `Report for ${fileName}`;
    const description = `This section describes the content of ${fileName}.`;

    const pdfBuffer = await exportHtmlToPdf(win, file, title, description);
    pdfDocs.push(pdfBuffer);
  }

  // Merge PDFs
  const mergedPdf = await PDFDocument.create();
  for (const pdfBytes of pdfDocs) {
    const doc = await PDFDocument.load(pdfBytes);
    const pages = await mergedPdf.copyPages(doc, doc.getPageIndices());
    pages.forEach((p) => mergedPdf.addPage(p));
  }

  fs.writeFileSync(outputPath, await mergedPdf.save());
  console.log("Merged PDF saved at:", outputPath);

  win.destroy();
}

app.whenReady().then(async () => {
  const htmlFiles = [
    path.join(__dirname, "file1.html"),
    path.join(__dirname, "file2.html"),
  ];

  await createMergedPdf(htmlFiles, path.join(__dirname, "output.pdf"));
  app.quit();
});
```

---

## 🔹 Why this is nice

* Keeps your injection script separate from app logic.
* You can style and extend the template (e.g. add HR, logo, date).
* Substitution is just `.replace()`, so you can later make it fancier with something like Mustache/Handlebars if needed.

---

👉 Do you also want me to show how to extend the template so that **each file starts on a new PDF page** (forcing a page break before inserting the next HTML)?

Ah 👍 I see — you want to prepare the whole header as a little chunk of HTML with placeholders (`@title`, `@description`), substitute values in Node/Electron, then inject that HTML string directly (instead of building DOM nodes line by line). That will keep the script very short.

Here’s how you can do it:

---

## 🔹 1. Prepare header template (separate file, e.g. `header-template.html`)

```html
<h3 style="text-align: center;">
  <span style="font-size: 18pt;">@title</span>
</h3>
<div style="text-align: center;">
  <em><span style="font-size: 12pt;">@description</span></em>
</div>
```

---

## 🔹 2. Load & substitute in main code

```js
const { app, BrowserWindow } = require("electron");
const path = require("path");
const fs = require("fs");
const { PDFDocument } = require("pdf-lib");

// Load HTML header template once
const headerTemplate = fs.readFileSync(
  path.join(__dirname, "header-template.html"),
  "utf-8"
);

async function exportHtmlToPdf(win, filePath, title, description) {
  await win.loadFile(filePath);

  // Substitute placeholders
  const headerHtml = headerTemplate
    .replace("@title", title)
    .replace("@description", description);

  // Insert header into the page
  await win.webContents.executeJavaScript(`
    const header = document.createElement("div");
    header.innerHTML = ${JSON.stringify(headerHtml)};
    document.body.insertBefore(header, document.body.firstChild);
  `);

  return await win.webContents.printToPDF({
    landscape: false,
    printBackground: true,
  });
}

async function createMergedPdf(htmlFiles, outputPath) {
  const win = new BrowserWindow({
    show: false,
    webPreferences: { offscreen: true },
  });

  const pdfDocs = [];

  for (const file of htmlFiles) {
    const fileName = path.basename(file, ".html");
    const title = `Report for ${fileName}`;
    const description = `This section describes ${fileName}.`;

    const pdfBuffer = await exportHtmlToPdf(win, file, title, description);
    pdfDocs.push(pdfBuffer);
  }

  // Merge PDFs
  const mergedPdf = await PDFDocument.create();
  for (const pdfBytes of pdfDocs) {
    const doc = await PDFDocument.load(pdfBytes);
    const pages = await mergedPdf.copyPages(doc, doc.getPageIndices());
    pages.forEach((p) => mergedPdf.addPage(p));
  }

  fs.writeFileSync(outputPath, await mergedPdf.save());
  console.log("Merged PDF saved at:", outputPath);

  win.destroy();
}

app.whenReady().then(async () => {
  const htmlFiles = [
    path.join(__dirname, "file1.html"),
    path.join(__dirname, "file2.html"),
  ];

  await createMergedPdf(htmlFiles, path.join(__dirname, "output.pdf"));
  app.quit();
});
```

---

## 🔹 How it works

* `header-template.html` holds your styled header skeleton.
* Before injection, Node replaces `@title` and `@description`.
* The result is inserted into the HTML body (`insertBefore` ensures it goes at the top).
* Chromium renders it normally → PDF.

---

👉 Do you want me to also add a **page-break CSS rule** into this header template, so each new file always starts on a new PDF page automatically?
