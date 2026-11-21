// 临时独立进程：静态服务 test_node_server/public/ 目录（8085 端口）。
// 用于在完整 index.js 无法重启期间（旧实例占用 4433）提供 redirect_*.html 测试页。
// 正式环境下这些文件由 index.js 8082 端口的 express.static 直接服务，本文件可删。
const http = require('http');
const fs = require('fs');
const path = require('path');

const PUBLIC_DIR = path.join(__dirname, 'public');
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png' };

http.createServer(function (req, res) {
    const name = path.normalize(decodeURIComponent(req.url.split('?')[0])).replace(/^([\\/])+/, '');
    const file = path.join(PUBLIC_DIR, name || 'redirect_start.html');
    if (!file.startsWith(PUBLIC_DIR) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
        res.statusCode = 404;
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.end('<h1>404</h1><p><a href="/redirect_start.html">redirect_start.html</a></p>');
    }
    res.setHeader('Content-Type', MIME[path.extname(file).toLowerCase()] || 'application/octet-stream');
    fs.createReadStream(file).pipe(res);
}).listen(8085);

console.log('Standalone static server for public/ listening on port 8085');
