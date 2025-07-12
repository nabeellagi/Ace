import L from "leaflet";
import "leaflet/dist/leaflet.css";

import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

const DefaultIcon = L.icon({
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

L.Marker.prototype.options.icon = DefaultIcon;


// Utility: Clean up raw KML HTML
function cleanDescription(desc) {
  return desc
    .replace(/<iframe.*?<\/iframe>/g, '')
    .replace(/style=".*?"/g, '')
    .replace(/width="\d+"/g, 'width="100%"')
    .replace(/height="\d+"/g, '');
}

// Create the map
const map = L.map("map", {
  worldCopyJump: false,
  maxBounds: [[-85, -180], [85, 180]],
  maxBoundsViscosity: 1.0,
  minZoom: 2,
  maxZoom: 9,
  zoomSnap: 1
}).setView([0, 0], 2);

// Add OpenStreetMap tiles
L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
  attribution: '© OpenStreetMap contributors'
}).addTo(map);

// Load KML and bind styled popups
omnivore.kml("/data/Radio-Telescope-Arrays-Worldwide-ClimateViewer-3D.kml")
  .on("ready", function () {
    map.fitBounds(this.getBounds());

    this.eachLayer(function (layer) {
      const props = layer.feature?.properties || {};
      const name = props.name || props.Name || "Unnamed Radio Telescope";
      const rawDesc = props.description || "";
      const cleanedDesc = cleanDescription(rawDesc);

      const popupContent = `
        <div class="popup-wrapper">
          <h3>${name}</h3>
          <div class="desc-content">${cleanedDesc}</div>
        </div>
      `;

      layer.bindPopup(popupContent, {
        maxWidth: 320,
        className: "custom-popup"
      });
    });
  })
  .addTo(map);
