import streamlit as st
import os

def app():
    # Inject CSS to remove Streamlit padding and set iframe fullscreen
    st.markdown("""
        <style>
            .main, .block-container {
                padding: 0 !important;
                margin: 0 !important;
            }
            .stApp {
                overflow: hidden;
            }
            iframe {
                position: fixed !important;
                top: 0; left: 0;
                height: 100vh !important;
                width: 100vw !important;
                border: none;
                z-index: 9999;
            }
        </style>
    """, unsafe_allow_html=True)

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    HOME_PATH = os.path.abspath(os.path.join(BASE_DIR, '..', '..', 'sections', 'home.html'))


    with open(HOME_PATH, "r", encoding="utf-8") as f:
        html_content = f.read()
    st.components.v1.html(html_content, height=1080, width=1920, scrolling=False)
