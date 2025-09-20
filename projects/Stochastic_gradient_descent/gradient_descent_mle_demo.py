"""
Gradient Descent & Log-Likelihood — Student Demo (Master ESA)
-------------------------------------------------------------
Tiny script that shows how gradient descent climbs a concave log-likelihood.

What it does
1) Defines a toy concave log-likelihood:  L(f) = -(f - f*)^2
2) Uses its gradient to perform gradient ascent (maximize L)
3) Plots the curve and the successive steps taken by the algorithm

How to run (locally)
    pip install numpy matplotlib
    python gradient_descent_mle_demo.py
"""

import numpy as np
import matplotlib.pyplot as plt

# ----------------- toy log-likelihood and its gradient -----------------
def log_likelihood(freq: float, f_star: float = 100.0) -> float:
    # Concave parabola with maximum at f_star
    return - (freq - f_star) ** 2

def grad_log_likelihood(freq: float, f_star: float = 100.0) -> float:
    # Derivative of L(f) = -(f - f*)^2  =>  dL/df = -2 (f - f*)
    return -2.0 * (freq - f_star)

# ------------------------- gradient ascent loop ------------------------
def gradient_ascent(
    f0: float,
    lr: float = 0.1,
    n_iter: int = 50,
    f_star: float = 100.0
):
    """Return the sequence of frequencies and their log-lik values."""
    path = [f0]
    vals = [log_likelihood(f0, f_star)]
    f = f0
    for _ in range(n_iter):
        g = grad_log_likelihood(f, f_star)
        f = f + lr * g                 # ascent step
        path.append(f)
        vals.append(log_likelihood(f, f_star))
    return np.array(path), np.array(vals)

# ------------------------------ run demo --------------------------------
if __name__ == "__main__":
    rng = np.random.default_rng(42)
    f0 = rng.uniform(85, 115)          # random starting frequency (MHz)
    lr = 0.1                           # learning rate
    n_iter = 50
    f_star = 100.0

    path, vals = gradient_ascent(f0, lr, n_iter, f_star)

    # Plot the log-likelihood curve
    x = np.linspace(85, 115, 500)
    L = log_likelihood(x, f_star)

    plt.figure(figsize=(10, 5))
    plt.plot(x, L, label="Log-likelihood L(f) = -(f - f*)²")
    # Plot the ascent path
    plt.scatter(path, vals, s=25, label="Gradient ascent steps")
    plt.plot(path, vals, linestyle="--", alpha=0.7)
    # Maximum location
    plt.axvline(f_star, color="gray", linestyle=":", label="True optimum f*")
    plt.title("Gradient Ascent on a Toy Log-Likelihood (radio frequency example)")
    plt.xlabel("Frequency f (MHz)")
    plt.ylabel("Log-likelihood L(f)")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.show()
