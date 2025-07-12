import L from "leaflet";
import "leaflet/dist/leaflet.css";
import * as satellite from "satellite.js";
import * as d3 from "d3";

// Create the Leaflet map with zoom and bounds constraints
const map = L.map("map", {
  worldCopyJump: false,
  maxBounds: [[-85, -180], [85, 180]],
  maxBoundsViscosity: 1.0,
  minZoom: 2,
  maxZoom: 9,
  zoomSnap: 1
}).setView([0, 0], 2);

// Add a tile layer (OpenStreetMap)
L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
  attribution: "&copy; OpenStreetMap contributors",
  maxZoom: 9,
  minZoom: 2,
}).addTo(map);

// Loading screen
const loadingScreen = d3.select("body")
  .append("div")
  .attr("id", "loading-screen")
  .style("position", "absolute")
  .style("top", "0")
  .style("left", "0")
  .style("width", "100%")
  .style("height", "100%")
  .style("background", "rgba(0, 0, 0, 0.7)")
  .style("color", "white")
  .style("display", "flex")
  .style("align-items", "center")
  .style("justify-content", "center")
  .style("font-size", "24px")
  .text("Loading Map...");

const EarthRadiusKm = 6371;

function parseTLE(text) {
  const lines = text.trim().split("\n");
  const satellites = [];
  for (let i = 0; i < lines.length - 2; i += 3) {
    const name = lines[i].trim();
    const tle1 = lines[i + 1].trim();
    const tle2 = lines[i + 2].trim();
    try {
      const satrec = satellite.twoline2satrec(tle1, tle2);
      satellites.push({ name, tle1, tle2, satrec, trail: [] });
    } catch (err) {
      console.warn(`Invalid TLE for ${name}`, err);
    }
  }
  return satellites;
}

function getLatLngFromSatrec(satrec, time = new Date()) {
  const positionAndVelocity = satellite.propagate(satrec, time);
  if (!positionAndVelocity.position) return null;
  const gmst = satellite.gstime(time);
  const geodeticCoords = satellite.eciToGeodetic(positionAndVelocity.position, gmst);
  const lat = satellite.degreesLat(geodeticCoords.latitude);
  const lon = satellite.degreesLong(geodeticCoords.longitude);
  const alt = geodeticCoords.height * EarthRadiusKm;
  return [lat, lon, alt];
}

const colorScale = d3.scaleOrdinal(d3.schemeCategory10);

// Load TLE
fetch("/data/active.tle")
  .then(res => res.text())
  .then(tleText => {
    const satellites = parseTLE(tleText).slice(0, 200);
    loadingScreen.remove();

    const trailsLayer = L.layerGroup().addTo(map);
    const markers = satellites.map((sat) => {
      const latlngData = getLatLngFromSatrec(sat.satrec);
      if (!latlngData) return null;
      const [lat, lon, alt] = latlngData;
      const category = sat.name.toLowerCase().includes("starlink")
        ? "Starlink"
        : sat.name.toLowerCase().includes("iss")
        ? "ISS"
        : "Other";

      const marker = L.circleMarker([lat, lon], {
        radius: 6,
        color: colorScale(category),
        fillOpacity: 0.9,
      })
        .addTo(map)
        .bindTooltip(() => `Name: ${sat.name}<br/>Lat: ${lat.toFixed(2)}&deg;<br/>Lon: ${lon.toFixed(2)}&deg;<br/>Alt: ${alt.toFixed(1)} km`);

      marker.on("click", () => {
        L.popup()
          .setLatLng([lat, lon])
          .setContent(
            `<strong>${sat.name}</strong><br/>` +
            `Latitude: ${lat.toFixed(2)}&deg;<br/>` +
            `Longitude: ${lon.toFixed(2)}&deg;<br/>` +
            `Altitude: ${alt.toFixed(1)} km`
          )
          .openOn(map);
      });

      sat.marker = marker;
      sat.trail = [];
      return sat;
    }).filter(Boolean);

    function updateSatellitePositions() {
      const now = new Date();
      trailsLayer.clearLayers();

      for (const sat of markers) {
        const latlngData = getLatLngFromSatrec(sat.satrec, now);
        if (!latlngData) continue;
        const [lat, lon, alt] = latlngData;

        sat.marker.setLatLng([lat, lon]);
        sat.trail.push([lat, lon]);
        if (sat.trail.length > 50) sat.trail.shift();

        if (sat.trail.length > 1) {
          L.polyline(sat.trail, {
            color: "lime",
            opacity: 0.4,
            weight: 1,
          }).addTo(trailsLayer);
        }
      }
    }

    setInterval(updateSatellitePositions, 1000);
  });
