import https from 'https';

const url = 'https://r.jina.ai/https://www.example.com';
const headers = {
  'Authorization': 'Bearer <insert from JINA_API_KEY env var>',
  'X-Engine': 'browser',
  'X-Respond-Timing': 'mutation-idle',
  'X-Retain-Images': 'none',
  'X-Retain-Links': 'gpt-oss',
  'X-Return-Format': 'markdown',
  'X-Robots-Txt': 'JinaReader',
  'X-Token-Budget': '75000',
  'X-With-Iframe': 'true',
  'X-With-Images-Summary': 'true'
};

const options = {
  method: 'GET',
  headers: headers
};

const request = https.request(url, options, (response) => {
  let data = '';

  response.on('data', (chunk) => {
    data += chunk;
  });

  response.on('end', () => {
    console.log(data);
  });
});

request.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

request.end();

