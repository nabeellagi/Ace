import streamlit as st
import math
import os
import json
import subprocess
from helper.constant import LOVE_PATH

G = 6.67430e-11  # gravitational constant in m^3 kg^-1 s^-2

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(1, 100), reset=False):
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
    st.title("🌟 Period of Binary Stars Calculator")
    st.markdown("""
    Estimate the **orbital period** of a binary star system.

    **Assumptions**:
    - Both stars have **equal mass**
    - Orbit is **circular**
    
    Using the formula:
    """)
    st.latex(r"T^2 = \frac{16 \pi^2 r^3}{G M}")

    reset = st.button("🔁 Reset to Default Values")

    # Inputs
    M, M_coeff, M_exp = scientific_input("Mass of one star (M) [kg]", "M", 1.989, 30, reset=reset)
    r, r_coeff, r_exp = scientific_input("Distance between stars (r) [m]", "r", 1.5, 11, reset=reset)

    if M > 0 and r > 0:
        numerator = 16 * math.pi**2 * r**3
        denominator = G * M
        T_squared = numerator / denominator
        T = math.sqrt(T_squared)

        T_days = T / (60 * 60 * 24)
        T_years = T_days / 365.25

        st.subheader("🕒 Orbital Period Result")
        st.write(f"**Period (seconds):** {T:,.3f} s")
        st.write(f"**Period (days):** {T_days:,.3f} days")
        st.write(f"**Period (years):** {T_years:,.5f} years")

        st.markdown("---")
        st.subheader("📘 Calculation Breakdown")
        st.latex(r"T^2 = \frac{16\pi^2 r^3}{G M}")
        st.latex(fr"""
            T^2 = \frac{{16 \times \pi^2 \times ({r_coeff} \times 10^{{{r_exp}}})^3}}{{6.674 \times 10^{{-11}} \times ({M_coeff} \times 10^{{{M_exp}}})}} 
            = {T_squared:,.3e}
        """)
        st.latex(fr"T = \sqrt{{{T_squared:,.3e}}} = {T:,.3f} \ \text{{s}}")

        if st.button("Launch"):
            os.makedirs("./visual/binary_stars", exist_ok=True)
            data = {
                "mass_one_star": {"value": M, "coeff": M_coeff, "exp": M_exp},
                "distance_between_stars": {"value": r, "coeff": r_coeff, "exp": r_exp},
                "T_squared": T_squared,
                "T_seconds": T,
                "T_days": T_days,
                "T_years": T_years
            }

            file_path = "./visual/binary_stars/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH  # Ensure this is in system PATH
            love_project_folder = os.path.abspath("./visual/binary_stars")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")
    else:
        st.warning("Mass and distance must be positive.")
