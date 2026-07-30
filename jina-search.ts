import https from 'https';

const url = 'https://s.jina.ai/?q=Jina+AI';
const options = {
  headers: {
    'Authorization': 'Bearer <insert from JINA_API_KEY env var>',
    'X-Return-Format': 'markdown'
  }
};

https.get(url, options, (res) => {
  let data = '';

  // A chunk of data has been received.
  res.on('data', (chunk) => {
    data += chunk;
  });

  // The whole response has been received.
  res.on('end', () => {
    console.log(data);
  });
}).on('error', (err) => {
  console.error(`Error: ${err.message}`);
});
