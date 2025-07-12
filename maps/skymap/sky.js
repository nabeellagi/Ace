import * as d3 from "d3";

const width = window.innerWidth;
const height = window.innerHeight;

const projection = d3.geoAzimuthalEquidistant()
  .scale(500)
  .translate([width / 2, height / 2])
  .rotate([0, -90]);

const pathGenerator = d3.geoPath().projection(projection);

const svg = d3.select("#sky-map")
  .append("svg")
  .attr("width", width)
  .attr("height", height)
  .style("background", "black");

// Loading screen
const loadingScreen = d3.select("body")
  .append("div")
  .attr("id", "loading-screen")
  .style("position", "absolute")
  .style("top", "0")
  .style("left", "0")
  .style("width", "100%")
  .style("height", "100%")
  .style("background", "rgba(0, 0, 0, 0.8)")
  .style("color", "white")
  .style("display", "flex")
  .style("align-items", "center")
  .style("justify-content", "center")
  .style("font-size", "24px")
  .text("Loading Sky Map...");

const zoomLayer = svg.append("g");
const rotateLayer = zoomLayer.append("g");

// Setup zoom
const zoom = d3.zoom()
  .scaleExtent([0.5, 10])
  .on("zoom", (event) => {
    zoomLayer.attr("transform", event.transform);
  });
svg.call(zoom);

// Rotation control
let rotationEnabled = true;
d3.timer((elapsed) => {
  if (rotationEnabled) {
    const angle = (elapsed * 0.005) % 360;
    rotateLayer.attr("transform", `rotate(${angle}, ${width / 2}, ${height / 2})`);
  }
});

// Keyboard toggle for rotation
window.addEventListener("keydown", (event) => {
  if (event.code === "Space") {
    rotationEnabled = !rotationEnabled;
  }
});

// Tooltip for star info
const tooltip = d3.select("body")
  .append("div")
  .style("position", "absolute")
  .style("padding", "4px 8px")
  .style("background", "rgba(0,0,0,0.7)")
  .style("color", "white")
  .style("border-radius", "4px")
  .style("pointer-events", "none")
  .style("font-size", "12px")
  .style("display", "none");

Promise.all([
  d3.csv("/data/hygdata_v37.csv"),
  d3.json("/data/constellations.lines.json")
]).then(([starData, constellationGeoJSON]) => {
  // Remove loading screen
  loadingScreen.remove();

  const stars = starData
    .filter(d => d.proper && isFinite(d.ra) && isFinite(d.dec))
    .map(d => ({
      name: d.proper.trim(),
      ra: +d.ra,
      dec: +d.dec,
      mag: +d.mag,
      con: d.con
    }));

  rotateLayer.selectAll("circle.star")
    .data(stars.filter(d => d.mag < 6))
    .enter()
    .append("circle")
    .attr("class", "star")
    .attr("cx", d => projection([d.ra * 15, d.dec])[0])
    .attr("cy", d => projection([d.ra * 15, d.dec])[1])
    .attr("r", d => Math.max(0.5, 6 - d.mag))
    .attr("fill", "white")
    .attr("opacity", 0.8)
    .on("mouseover", (event, d) => {
      tooltip.style("display", "block")
        .html(`<strong>${d.name}</strong><br>Mag: ${d.mag}<br>Con: ${d.con}`);
    })
    .on("mousemove", (event) => {
      tooltip.style("left", `${event.pageX + 10}px`)
        .style("top", `${event.pageY - 20}px`);
    })
    .on("mouseout", () => {
      tooltip.style("display", "none");
    });

  rotateLayer.selectAll("path.constellation-line")
    .data(constellationGeoJSON.features)
    .enter()
    .append("path")
    .attr("class", "constellation-line")
    .attr("d", d => pathGenerator(d))
    .attr("stroke", "#3399ff")
    .attr("stroke-width", 2)
    .attr("fill", "none")
    .attr("opacity", 0.6);

  rotateLayer.selectAll("text.constellation-label")
    .data(constellationGeoJSON.features)
    .enter()
    .append("text")
    .attr("class", "constellation-label")
    .attr("x", d => pathGenerator.centroid(d)[0])
    .attr("y", d => pathGenerator.centroid(d)[1])
    .attr("fill", "#88ccff")
    .attr("font-size", "10px")
    .attr("font-weight", "bold")
    .attr("text-anchor", "middle")
    .attr("pointer-events", "none")
    .text(d => d.id || d.properties?.name || "Unnamed");

  // Latitude and longitude lines
  const graticule = d3.geoGraticule();
  rotateLayer.append("path")
    .datum(graticule())
    .attr("d", pathGenerator)
    .attr("stroke", "white")
    .attr("stroke-width", 0.5)
    .attr("fill", "none")
    .attr("opacity", 0.3);

}).catch(err => {
  console.error("Error loading sky data:", err);
});