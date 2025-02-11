const express = require('express');
const path = require('path');
const multer = require('multer');
const fs = require('fs');
const unzipper = require('unzipper');
const { Extract } = require('node-unrar-js');

const app = express();
const port = process.env.PORT || 3000;

const upload = multer({ dest: 'uploads/' });

app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.render('index');
});

app.post('/upload', upload.single('file'), async (req, res) => {
  const filePath = req.file.path;
  const fileExtension = path.extname(filePath).toLowerCase();

  if (fileExtension === '.zip') {
    await extractZIP(filePath, 'extracted_files');
    res.send('تم فك ضغط الملف ZIP بنجاح!');
  } else if (fileExtension === '.rar') {
    await extractRAR(filePath, 'extracted_files');
    res.send('تم فك ضغط الملف RAR بنجاح!');
  } else if (fileExtension === '.bin') {
    const data = readBINFile(filePath);
    const dtcCodes = extractDTCs(data);
    res.render('dtcForm', { dtcCodes });
  } else {
    res.send('الملف غير مدعوم!');
  }
});

function extractDTCs(data) {
  const dtcPattern = /P[0-9A-F]{4}/g;
  const textData = data.toString('utf-8');
  return [...new Set(textData.match(dtcPattern) || [])];
}

function readBINFile(filePath) {
  return fs.readFileSync(filePath);
}

async function extractZIP(filePath, outputDir) {
  await fs.createReadStream(filePath).pipe(unzipper.Extract({ path: outputDir })).promise();
}

async function extractRAR(filePath, outputDir) {
  const buf = Uint8Array.from(fs.readFileSync(filePath)).buffer;
  const extractor = await Extract({ data: buf });
  for (const file of extractor.extract().files) {
    const extractedPath = path.join(outputDir, file.fileHeader.name);
    if (file.fileHeader.flags.directory) {
      fs.mkdirSync(extractedPath, { recursive: true });
    } else {
      fs.writeFileSync(extractedPath, Buffer.from(file.extraction));
    }
  }
}

app.listen(port, () => console.log(`Server running on port ${port}`));