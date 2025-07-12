import streamlit as st
import math
import json
import os
import subprocess
import matplotlib.pyplot as plt
from helper.constant import LOVE_PATH

# Gravitational constant
G = 6.67430e-11  # m^3 kg^-1 s^-2

# Ensure ./visual/orbit directory exists
os.makedirs("./visual/orbits", exist_ok=True)

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
    st.title("🌌 Orbital Period Calculator — Multi Launch Mode")
    st.markdown("Calculate and **store** the orbital periods for **2 to 5 planets** orbiting one central body.")

    reset = st.button("🔁 Reset to Default Values")
    num_planets = st.slider("🔢 Number of Planets", min_value=2, max_value=5, value=5)
    show_latex = st.checkbox("📜 Show LaTeX Calculation Process", value=True)

    st.subheader("🌞 Central Object (Star)")
    M, M_coeff, M_exp = scientific_input("Mass of central object (M) [kg]", "M", 1.989, 30, reset=reset)

    st.markdown("---")
    st.subheader("�� Planets")

    planet_data = []

    for i in range(1, num_planets + 1):
        st.markdown(f"### Planet {i}")

        m, m_coeff, m_exp = scientific_input(f"Mass of Planet {i} (m) [kg]", f"m{i}", 5.972, 24, reset=reset)
        a, a_coeff, a_exp = scientific_input(f"Semi-major Axis (a) [m]", f"a{i}", 1.496 + i - 1, 11, reset=reset)

        ecc_key = f"e{i}"
        if reset:
            st.session_state[ecc_key] = 0.0167
        e = st.number_input(f"Eccentricity (e) of Planet {i}", key=ecc_key, min_value=0.0, max_value=1.0, value=st.session_state.get(ecc_key, 0.0167), step=0.0001)

        if M > 0 and m > 0 and a > 0:
            T_squared = (4 * math.pi**2 * a**3) / (G * (M + m))
            T_seconds = math.sqrt(T_squared)
            T_days = T_seconds / (60 * 60 * 24)
            T_years = T_days / 365.25

            planet_data.append({
                "planet": f"Planet {i}",
                "mass": {"value": m, "coeff": m_coeff, "exp": m_exp},
                "semi_major_axis": {"value": a, "coeff": a_coeff, "exp": a_exp},
                "eccentricity": e,
                "T_seconds": T_seconds,
                "T_days": T_days,
                "T_years": T_years
            })

            with st.expander(f"📊 Planet {i} Result", expanded=True):
                st.write(f"**T (seconds):** {T_seconds:,.3f}")
                st.write(f"**T (days):** {T_days:,.3f}")
                st.write(f"**T (years):** {T_years:,.6f}")

                if show_latex:
                    st.markdown("**LaTeX Breakdown**")
                    st.latex(r"T^2 = \frac{4\pi^2 a^3}{G(M + m)}")
                    st.latex(fr"""
                        T^2 = \frac{{4 \times \pi^2 \times ({a_coeff} \times 10^{{{a_exp}}})^3}} 
                        {{6.67430 \times 10^{{-11}} \times (({M_coeff} \times 10^{{{M_exp}}}) + ({m_coeff} \times 10^{{{m_exp}}}))}}
                    """)
                    st.latex(fr"T = \sqrt{{T^2}} = {T_seconds:,.3f} \ \text{{seconds}}")
        else:
            st.warning(f"Planet {i} has invalid input and will be skipped in calculations.")

    if planet_data:
        st.markdown("---")
        st.subheader("📈 Orbital Period Comparison")

        planet_names = [p["planet"] for p in planet_data]
        periods_years = [p["T_years"] for p in planet_data]

        fig, ax = plt.subplots(figsize=(8, 5))
        ax.bar(planet_names, periods_years, color='royalblue')
        ax.set_title("Orbital Periods of Planets")
        ax.set_xlabel("Planet")
        ax.set_ylabel("Period (years)")
        ax.grid(True, linestyle='--', alpha=0.6)
        for i, v in enumerate(periods_years):
            ax.text(i, v + 0.05, f"{v:.3f} yr", ha='center', va='bottom')

        st.pyplot(fig)

    if st.button("Launch"):
        if len(planet_data) >= 2:
            output_data = {
                "central_mass": {
                    "value": M,
                    "coeff": M_coeff,
                    "exp": M_exp
                },
                "planets": planet_data
            }

            file_path = "./visual/orbits/data.json"
            with open(file_path, "w") as f:
                json.dump(output_data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(output_data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/orbits")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🔀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Could not launch Love2D. Make sure it is installed and available in your PATH.")
        else:
            st.error("🚫 At least two valid planets are required to save the data.")
