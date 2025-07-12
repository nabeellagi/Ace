import streamlit as st
from sections import fluxlumi, home, orbit, orbits_many, roche, escape, gravity, hyp_binary, blackhole, starchart_map, satelite_map, rt_map, parallax
import base64
from pathlib import Path

# --- Page Definitions ---
ALL_PAGES = {
    "Home": home,
    "One Orbit": orbit,
    "Multiple Orbit": orbits_many,
    "Roche Limit": roche,
    "Escape Velocity": escape,
    "Surface Gravity": gravity,
    "Hypothetical Binary Star": hyp_binary,
    "Schwarzschild Radius": blackhole,
    "Luminosity and Flux on Star": fluxlumi,
    "Constellations on Sky": starchart_map,
    "Satelite Map": satelite_map, 
    "Radio Telescope" : rt_map,
    "Parallax" : parallax
}

# --- Groupings Referencing ALL_PAGES ---
ASTRO_KEYS = [
    "One Orbit", "Multiple Orbit", "Roche Limit", "Escape Velocity", "Surface Gravity",
    "Hypothetical Binary Star", "Schwarzschild Radius", "Luminosity and Flux on Star", "Parallax"
]
MAP_KEYS = ["Constellations on Sky", "Satelite Map", "Radio Telescope"]

ASTRO_PAGES = {k: ALL_PAGES[k] for k in ASTRO_KEYS}
MAP_PAGES = {k: ALL_PAGES[k] for k in MAP_KEYS}

# --- Font & Icon Setup ---
st.markdown("""
<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
<style>
@import url('https://fonts.googleapis.com/css2?family=Balsamiq+Sans:wght@400;700&display=swap');
html, body, div, span, p, h1, h2, h3, h4, h5, h6, label, input, textarea, button {
    font-family: 'Balsamiq Sans', cursive !important;
}
.material-icons, [class*="material-icons"], .st-emotion-cache-eaemma {
    font-family: 'Material Icons' !important;
    font-style: normal;
    font-weight: normal;
    speak: none;
    display: inline-block;
    line-height: 1;
    text-transform: none;
    letter-spacing: normal;
    white-space: nowrap;
    direction: ltr;
    -webkit-font-feature-settings: 'liga';
    -webkit-font-smoothing: antialiased;
}
            
</style>
""", unsafe_allow_html=True)

st.markdown("""
<style>
html, body {
    overscroll-behavior: none;
    overflow: hidden !important;
    position: fixed !important;
    width: 100%;
    height: 100%;
    margin: 0;
    padding: 0;
}
#root {
    overflow: hidden !important;
}
</style>
<script>
window.addEventListener('load', () => {
    document.documentElement.style.overflow = 'hidden';
    document.body.style.overflow = 'hidden';
    window.scrollTo(0, 0);
});
setInterval(() => {
    if (window.scrollY !== 0) {
        window.scrollTo(0, 0);
    }
}, 60);
</script>
""", unsafe_allow_html=True)


st.markdown("""
<style>
footer, #MainMenu, header {
    visibility: hidden;
}
</style>
""", unsafe_allow_html=True)

# --- Reduce spacing & restore clean sidebar button style ---
st.markdown("""
<style>
/* Sidebar button style only */
section[data-testid="stSidebar"] button {
    border: none !important;
    background-color: transparent !important;
    text-align: left;
    padding: 0.05rem 0.25rem !important;
    margin: 0.05rem 0 !important;
    font-size: 0.95rem;
    color: inherit;
    box-shadow: none !important;
}

/* Compact spacing between layout blocks */
section[data-testid="stSidebar"] div[data-testid="stVerticalBlock"] {
    row-gap: 0.05rem !important;
    gap: 0.05rem !important;
}
</style>
""", unsafe_allow_html=True)

# --- Sidebar UI ---
st.sidebar.title("🔭 Ace Navigation")
search_query = st.sidebar.text_input("🔍 Search pages").lower()

# --- Display Buttons by Section ---
def display_page_buttons(section_title, page_dict):
    st.sidebar.markdown(f"### {section_title}")
    for name, module in page_dict.items():
        if search_query in name.lower():
            if st.sidebar.button(f"{name}"):
                st.session_state.page_to_load = name

# --- Session State Init ---
if "page_to_load" not in st.session_state:
    st.session_state.page_to_load = "Home"

# --- Display Home if visible ---
if search_query in "home":
    if st.sidebar.button("🏠 Home"):
        st.session_state.page_to_load = "Home"

# --- Render Sections ---
display_page_buttons("Astrophysics", ASTRO_PAGES)
display_page_buttons("Maps", MAP_PAGES)

# --- Load Selected Page ---
current_page = ALL_PAGES.get(st.session_state.page_to_load, home)
current_page.app()

# --- Custom Cursors ---
def get_base64_image(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

BASE_DIR = Path(__file__).parent
IMAGE_DIR = BASE_DIR / "images"

normal_cursor = get_base64_image(IMAGE_DIR / "normal.png")
hoverb_cursor = get_base64_image(IMAGE_DIR / "hoverb.png")
hovert_cursor = get_base64_image(IMAGE_DIR / "hovert.png")

st.markdown(f"""
<style>
html, body, [data-testid="stAppViewContainer"] {{
    cursor: url("data:image/png;base64,{normal_cursor}"), auto;
}}
html {{ scroll-behavior: smooth; }}

div[data-testid="baseButton"]:hover,
button:hover {{
    cursor: url("data:image/png;base64,{hoverb_cursor}"), pointer;
}}

input:hover,
textarea:hover,
div[data-baseweb="input"] input:hover {{
    cursor: url("data:image/png;base64,{hovert_cursor}"), text;
}}

</style>
""", unsafe_allow_html=True)