import * as https from 'https';

const data = JSON.stringify({
    model: "jina-deepsearch-v1",
    messages: [
        {
            role: "user",
            content: "Hi!"
        },
        {
            role: "assistant",
            content: "Hi, how can I help you?"
        },
        {
            role: "user",
            content: "what's the latest blog post from jina ai?"
        }
    ],
    stream: true,
    reasoning_effort: "medium"
});

const options = {
    hostname: 'deepsearch.jina.ai',
    path: '/v1/chat/completions',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer <insert from JINA_API_KEY env var>',
        'Content-Length': data.length
    }
};

const req = https.request(options, (res) => {
    let responseData = '';

    res.on('data', (chunk) => {
        responseData += chunk;
    });

    res.on('end', () => {
        console.log(responseData);
    });
});

req.on('error', (error) => {
    console.error(error);
});

// Write data to request body
req.write(data);
req.end();
