// Example of the server https is taken from here: https://engineering.circle.com/https-authorized-certs-with-node-js-315e548354a2
// Renew certificates:
// - openssl x509 -req -extfile server.cnf -days 9999 -passin "pass:password" -in server-csr.pem -CA ca-crt.pem -CAkey ca-key.pem -CAcreateserial -out server-crt.pem
// - openssl x509 -req -extfile client1.cnf -days 9999 -passin "pass:password" -in client1-csr.pem -CA ca-crt.pem -CAkey ca-key.pem -CAcreateserial -out client1-crt.pem
// - openssl x509 -req -extfile client2.cnf -days 9999 -passin "pass:password" -in client2-csr.pem -CA ca-crt.pem -CAkey ca-key.pem -CAcreateserial -out client2-crt.pem
// Verify certificates:
// - openssl verify -CAfile ca-crt.pem server-crt.pem
// - openssl verify -CAfile ca-crt.pem client1-crt.pem
// - openssl verify -CAfile ca-crt.pem client2-crt.pem
// Conversion of client1-crt.pem to certificate.pfx: https://stackoverflow.com/a/38408666/4637638
// - openssl pkcs12 -export -out certificate.pfx -inkey client1-key.pem -in client1-crt.pem -certfile ca-crt.pem
// - Overwrite certificate.pfx to example/test_assets/certificate.pfx
const express = require('express');
const http = require('http');
const https = require('https');
const cors = require('cors');
const auth = require('basic-auth');
const app = express();
const appHttps = express();
const appAuthBasic = express();
const fs = require('fs')
const path = require('path')
const bodyParser = require('body-parser');
const multiparty = require('multiparty');

var options = {
  key: fs.readFileSync('server-key.pem'),
  cert: fs.readFileSync('server-crt.pem'),
  ca: fs.readFileSync('ca-crt.pem'),
  requestCert: true,
  rejectUnauthorized: false,
  ciphers: "DEFAULT:@SECLEVEL=0"
};

appHttps.get('/', (req, res) => {
  console.log(JSON.stringify(req.headers))
	const cert = req.connection.getPeerCertificate()

  // The `req.client.authorized` flag will be true if the certificate is valid and was issued by a CA we white-listed
  // earlier in `opts.ca`. We display the name of our user (CN = Common Name) and the name of the issuer, which is
  // `localhost`.

	if (req.client.authorized) {
		res.send(`
      <html>
        <head>
        </head>
        <body>
          <h1>Authorized</h1>
        </body>
      </html>
    `);
  // They can still provide a certificate which is not accepted by us. Unfortunately, the `cert` object will be an empty
  // object instead of `null` if there is no certificate at all, so we have to check for a known field rather than
  // truthiness.

	} else if (cert.subject) {
    console.log(`Sorry ${cert.subject.CN}, certificates from ${cert.issuer.CN} are not welcome here.`);
		res.status(403).send(`
      <html>
        <head>
        </head>
        <body>
          <h1>Forbidden</h1>
        </body>
      </html>
    `);
  // And last, they can come to us with no certificate at all:
	} else {
	  console.log(`Sorry, but you need to provide a client certificate to continue.`)
		res.status(401).send(`
      <html>
        <head>
        </head>
        <body>
          <h1>Unauthorized</h1>
        </body>
      </html>
    `);
	}
	res.end()
})

// Let's create our HTTPS server and we're ready to go.
https.createServer(options, appHttps).listen(4433)



// Ensure this is before any other middleware or routes
appAuthBasic.use((req, res, next) => {
  let user = auth(req)

  if (user === undefined || user['name'] !== 'USERNAME' || user['pass'] !== 'PASSWORD') {
    res.statusCode = 401
    res.setHeader('WWW-Authenticate', 'Basic realm="Node"')
    res.send(`
        <html>
          <head>
          </head>
          <body>
            <h1>Unauthorized</h1>
          </body>
        </html>
      `);
    res.end()
  } else {
    next()
  }
});

appAuthBasic.use(express.static(__dirname + '/public'));

appAuthBasic.get("/", (req, res) => {
  console.log(JSON.stringify(req.headers))
  res.send(`
    <html>
      <head>
      </head>
      <body>
        <h1>Authorized</h1>
      </body>
    </html>
  `);
  res.end()
});

appAuthBasic.get('/test-index', (req, res) => {
    res.sendFile(__dirname + '/public/test-index.html');
});

appAuthBasic.listen(8081);


app.use(cors());

app.use(bodyParser.urlencoded({extended: false, limit: '10mb'}));
// Parse JSON bodies (as sent by API clients)
app.use(bodyParser.json({limit: '10mb'}));

app.use(express.static(__dirname + '/public'));

app.get("/", (req, res) => {
  console.log(JSON.stringify(req.headers))
  res.send(`
    <html>
      <head>
      </head>
      <body>
        <p>HELLO</p>
      </body>
    </html>
  `);
  res.end()
})

app.get("/echo-headers", (req, res) => {
  res.send(`
    <html>
      <head>
      </head>
      <body>
        <pre style="word-wrap: break-word; white-space: pre-wrap;">${JSON.stringify(req.headers)}</pre>
      </body>
    </html>
  `);
  res.end()
})

app.get('/test-index', (req, res) => {
    res.sendFile(__dirname + '/public/test-index.html');
})

// shouldInterceptRequest POST body 加固用例专用页面：
// 页面内发起一个 fetch 请求，收到响应后回传 Dart。
// 用服务器页面加载，避免 data: 源被 useShouldInterceptRequest 拦截后
// fallback 失败（Cannot fetch non-http local resource）导致页面 JS 不执行。
//
// 查询参数：
//   method   请求方法（POST/PUT/PATCH），默认 POST
//   target   完整目标 URL（默认同源 /test-ajax-post）
//   bodyType body 类型：json（默认）/ formdata / large
//   size     large 类型时 body 字节数（默认 1048576）
//   preflight=1 时追加 X-Requested-With 自定义头，跨域时触发 OPTIONS 预检
function serveTestPostBodyPage(req, res) {
  const method = req.query.method || 'POST';
  const target = req.query.target || 'http://' + req.headers.host + '/test-ajax-post';
  const bodyType = req.query.bodyType || 'json';
  const size = parseInt(req.query.size, 10) || 1048576;
  const preflight = req.query.preflight === '1';
  res.setHeader('Content-Type', 'text/html');
  res.end(`
<!doctype html>
<html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'>
        <meta http-equiv='X-UA-Compatible' content='ie=edge'>
        <title>InAppWebViewPostBodyTest</title>
    </head>
    <body>
        <h1>InAppWebViewPostBodyTest</h1>
        <script>
          window.addEventListener('flutterInAppWebViewPlatformReady', function(event) {
            var method = '${method}';
            var target = '${target}';
            var headers = {};
            var body = null;
            if ('${bodyType}' === 'formdata') {
              var formData = new FormData();
              formData.append('firstname', 'Foo');
              formData.append('lastname', 'Bar');
              body = formData;
            } else if ('${bodyType}' === 'large') {
              headers['Content-Type'] = 'application/json';
              body = JSON.stringify({ data: 'x'.repeat(${size}) });
            } else {
              // GET/HEAD 不允许携带 body，仅 POST/PUT/PATCH 设置 JSON body。
              if (method !== 'GET' && method !== 'HEAD') {
                headers['Content-Type'] = 'application/json';
                body = JSON.stringify({firstname: 'Foo', lastname: 'Bar', method: method});
              }
            }
            if (${preflight}) {
              headers['X-Requested-With'] = 'XMLHttpRequest';
            }
            fetch(target, {
                method: method,
                headers: headers,
                body: body
              })
              .then(function(response) {
                return response.json();
              })
              .then(function(value) {
                window.flutter_inappwebview.callHandler('postResult', value);
              })
              .catch(function(error) {
                window.flutter_inappwebview.callHandler('postResult', 'ERROR: ' + error);
              });
          });
        </script>
    </body>
</html>
  `);
}

app.get('/test-post-body-page', (req, res) => {
  serveTestPostBodyPage(req, res);
})

app.post('/test-post', (req, res) => {
  console.log(JSON.stringify(req.headers))
  console.log(JSON.stringify(req.body))
  res.send(`
    <html>
      <head>
      </head>
      <body>
        <p>HELLO ${req.body.name}!</p>
      </body>
    </html>
  `);
  res.end()
})

app.post("/test-ajax-post", (req, res) => {
  console.log(JSON.stringify(req.headers));
  if (req.headers["content-type"].indexOf("multipart/form-data;") === 0) {
    const form = new multiparty.Form();
    form.parse(req, function(err, fields, files) {
      console.log(fields);
      res.set("Content-Type", "application/json")
      res.send(JSON.stringify({
        "firstname": fields.firstname[0],
        "lastname": fields.lastname[0],
      }));
      res.end();
    });
  } else {
    console.log(req.body);
    res.set("Content-Type", "application/json")
    res.send(JSON.stringify({
      "firstname": req.body.firstname,
      "lastname": req.body.lastname,
    }));
    res.end();
  }
})

// PUT/PATCH 版本的 test-ajax-post：回显 method + body，供
// shouldInterceptRequest POST body 加固用例验证 PUT/PATCH 请求 body 不丢失。
app.put('/test-ajax-post', (req, res) => {
  echoAjaxBody(req, res, 'PUT');
})

app.patch('/test-ajax-post', (req, res) => {
  echoAjaxBody(req, res, 'PATCH');
})

function echoAjaxBody(req, res, method) {
  console.log(JSON.stringify(req.headers));
  if (req.headers['content-type'].indexOf('multipart/form-data;') === 0) {
    const form = new multiparty.Form();
    form.parse(req, function(err, fields, files) {
      console.log(fields);
      res.set('Content-Type', 'application/json')
      res.send(JSON.stringify({
        'method': method,
        'firstname': fields.firstname[0],
        'lastname': fields.lastname[0],
      }));
      res.end();
    });
  } else {
    console.log(req.body);
    res.set('Content-Type', 'application/json')
    res.send(JSON.stringify({
      'method': method,
      'firstname': req.body.firstname,
      'lastname': req.body.lastname,
    }));
    res.end();
  }
}

// 通用回显接口：任意 method，回显 method 与完整 body。
// 用于 shouldInterceptRequest POST body 加固用例验证 body 完整性与大体积 body。
app.all('/test-echo-body', (req, res) => {
  console.log(JSON.stringify(req.headers));
  console.log(req.method);
  console.log(JSON.stringify(req.body));
  let bodyLength = 0;
  let body = null;
  if (req.body != null) {
    body = req.body;
    bodyLength = typeof req.body === 'string'
      ? req.body.length
      : JSON.stringify(req.body).length;
  }
  res.set('Content-Type', 'application/json')
  res.send(JSON.stringify({
    'method': req.method,
    'body': body,
    'bodyLength': bodyLength,
  }));
  res.end();
})

app.get("/test-download-file", (req, res) => {
  console.log(JSON.stringify(req.headers))
  const filePath = path.join(__dirname, 'assets', 'flutter_logo.png');
  const stat = fs.statSync(filePath);
  const file = fs.readFileSync(filePath, 'binary');
  res.setHeader('Content-Length', stat.size);
  res.setHeader('Content-Type', 'image/png');
  res.setHeader('Content-Disposition', 'attachment; filename=flutter_logo.png');
  res.write(file, 'binary');
  res.end();
})

app.listen(8082)

// Proxy server (8083)：原版透传服务，供代理相关用例使用。保持原样，不做任何扩展。
http.createServer(function (req, res) {
    res.setHeader('Content-type', 'text/html');
    res.write(`
        <html>
          <head>
          </head>
          <body>
            <h1>Proxy Works</h1>
            <p id="url">${req.url}</p>
            <p id="method">${req.method}</p>
            <p id="headers">${JSON.stringify(req.headers)}</p>
          </body>
        </html>
      `);
    res.end();
}).listen(8083);

// 8084：shouldInterceptRequest POST body 跨域测试页面的独立源（与 8082/8083 不同源）。
// 页面从 8084 加载，页面内 fetch 目标为 8082 → 触发 OPTIONS 预检（由 8082 的 cors 处理）。
// 全新端口，不影响原版 8082/8083 服务功能。
http.createServer(function (req, res) {
    if (req.url.split('?')[0] === '/test-post-body-page') {
      const q = new URL(req.url, 'http://' + req.headers.host).searchParams;
      req.query = {
        method: q.get('method'),
        target: q.get('target'),
        bodyType: q.get('bodyType'),
        size: q.get('size'),
        preflight: q.get('preflight'),
      };
      return serveTestPostBodyPage(req, res);
    }
    res.setHeader('Content-type', 'text/html');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Requested-With');
    if (req.method === 'OPTIONS') {
      res.statusCode = 204;
      return res.end();
    }
    res.write(`
        <html>
          <head>
          </head>
          <body>
            <h1>Proxy Works</h1>
            <p id="url">${req.url}</p>
            <p id="method">${req.method}</p>
            <p id="headers">${JSON.stringify(req.headers)}</p>
          </body>
        </html>
      `);
    return res.end();
}).listen(8084);