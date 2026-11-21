const app = document.getElementById('app');
const logo = document.getElementById('logo');

app.innerHTML =
  '<h2>Vite SPA Mounted</h2>' +
  '<p id="status">ES module executed successfully.</p>';

window.__VITE_SPA_DEMO__ = {
  mounted: true,
  moduleBytes: document.currentScript?.src ?? '',
  logoNaturalWidth: logo?.naturalWidth ?? 0,
  logoNaturalHeight: logo?.naturalHeight ?? 0,
  timestamp: Date.now(),
};

console.log('[vite-spa-demo] mounted', JSON.stringify(window.__VITE_SPA_DEMO__));
