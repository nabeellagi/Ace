import streamlit as st
import os
import json
import subprocess
import numpy as np
import matplotlib.pyplot as plt
from helper.constant import LOVE_PATH

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(-6, 2), reset=False):
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
            format="%.6f"
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
    st.title("🌌 Stellar Parallax Distance Calculator")
    st.markdown("Estimate the **distance** to a star using either the **parallax angle** or directly the **distance in parsecs**.")

    reset = st.button("🔁 Reset to Default Value")

    sync_mode = st.radio("Choose input mode:", ["Input Parallax (p)", "Input Distance (d)"])

    if sync_mode == "Input Parallax (p)":
        p, p_coeff, p_exp = scientific_input("Parallax (p) [arcsec]", "p", 7.687, -1, exp_range=(-6, 2), reset=reset)
        d = 1 / p if p > 0 else None
    else:
        d, d_coeff, d_exp = scientific_input("Distance (d) [parsecs]", "d", 1.301, 0, exp_range=(-3, 6), reset=reset)
        p = 1 / d if d > 0 else None
        p_coeff = p / (10 ** int(f"{p:.1e}".split("e")[1])) if p else 0
        p_exp = int(f"{p:.1e}".split("e")[1]) if p else 0

    if p and d:
        st.subheader("📏 Distance Result")
        st.write(f"**Distance (parsecs):** {d:,.5f} pc")
        st.write(f"**Distance (light-years):** {d * 3.26156:,.5f} ly")

        st.markdown("---")
        st.subheader("📘 Formula Breakdown")
        st.latex(r"d = \frac{1}{p}")
        st.latex(fr"""
            d = \frac{{1}}{{{p_coeff:.4f} \times 10^{{{p_exp}}}}} = {d:,.5f} \ \text{{pc}}
        """)

        st.markdown("---")
        st.subheader("📊 Parallax-Distance Relationship")

        p_vals = np.logspace(-6, 0, 500)
        d_vals = 1 / p_vals

        fig, ax = plt.subplots()
        ax.plot(p_vals, d_vals, label='d = 1/p', color='blue')
        ax.scatter([p], [d], color='red', zorder=5)
        ax.text(p, d, f"({p:.3e}, {d:.2f} pc)", color='red', ha='left', va='bottom')

        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.set_xlabel("Parallax (arcsec)")
        ax.set_ylabel("Distance (parsecs)")
        ax.set_title("Parallax vs. Distance")
        ax.grid(True, which='both', linestyle='--', alpha=0.5)
        ax.legend()

        st.pyplot(fig)

        if st.button("Launch"):
            os.makedirs("./visual/parallax", exist_ok=True)

            data = {
                "parallax_arcsec": {"value": p, "coeff": p_coeff, "exp": p_exp},
                "distance_pc": d,
                "distance_ly": d * 3.26156
            }

            file_path = "./visual/parallax/data.json"
            with open(file_path, "w", encoding='utf-8') as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/parallax")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🔀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")

    else:
        st.warning("Parallax and distance must be positive values.")
