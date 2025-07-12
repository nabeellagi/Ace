import streamlit as st
import math
import os
import json
import subprocess
from helper.constant import LOVE_PATH

# Constants
G = 6.67430e-11  # Gravitational constant (m³·kg⁻¹·s⁻²)
c = 299_792_458  # Speed of light in vacuum (m/s)

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(1, 100), reset=False):
    """Creates a scientific notation input with coefficient and exponent."""
    if reset:
        st.session_state[f"{key_prefix}_coeff"] = default_coeff
        st.session_state[f"{key_prefix}_exp"] = default_exp

    cols = st.columns([3, 2])
    with cols[0]:
        coeff = st.number_input(
            f"{label} - Coefficient", 
            key=f"{key_prefix}_coeff", 
            value=default_coeff, 
            step=0.001, 
            format="%.3f"
        )
    with cols[1]:
        exp = st.number_input(
            f"{label} - Exponent", 
            key=f"{key_prefix}_exp", 
            value=default_exp, 
            step=1, 
            min_value=exp_range[0], 
            max_value=exp_range[1]
        )
    return coeff * (10 ** exp), coeff, exp

def app():
    st.title("🕳️ Schwarzschild Radius Calculator")
    st.markdown("Estimate the event horizon (Schwarzschild radius) of a black hole from its mass.")

    reset = st.button("🔁 Reset to Default Mass")

    # Input: Mass of the black hole
    M, M_coeff, M_exp = scientific_input("Black Hole Mass (kg)", "M", 1.989, 30, reset=reset)  # Sun mass by default

    if M > 0:
        # Calculation: Schwarzschild radius
        Rs = (2 * G * M) / (c ** 2)  # in meters
        Rs_km = Rs / 1000

        st.subheader("🧮 Schwarzschild Radius Results")
        st.write(f"**Rₛ (meters):** {Rs:,.3f} m")
        st.write(f"**Rₛ (kilometers):** {Rs_km:,.3f} km")

        st.markdown("---")
        st.subheader("📘 Calculation Breakdown")
        st.latex(r"R_s = \frac{2GM}{c^2}")

        st.latex(fr"""
            R_s = \frac{{2 \times 6.67430 \times 10^{{-11}} \times ({M_coeff} \times 10^{{{M_exp}}})}}
            {{(2.99792458 \times 10^8)^2}} = {Rs:,.3f} \ \text{{meters}}
        """)

        st.markdown(f"This is the radius of the event horizon for a non-rotating, uncharged black hole with mass **{M_coeff} × 10^{M_exp} kg**.")

        # Optional: Save or launch
        if st.button("Launch"):
            os.makedirs("./visual/blackhole", exist_ok=True)
            data = {
                "mass": {"value": M, "coeff": M_coeff, "exp": M_exp},
                "schwarzschild_radius_m": Rs,
                "schwarzschild_radius_km": Rs_km
            }

            file_path = "./visual/blackhole/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/blackhole")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please ensure it's installed and in your PATH.")
    else:
        st.warning("Mass must be a positive value.")
