This student project (Master ESA) is a small, self-contained Shiny app for credit-risk modeling. It loads the public UCI Credit Card dataset (auto-downloaded on first run), fits a simple logistic regression to predict default, and provides an interactive interface to explore variables, inspect model coefficients, evaluate performance, and generate individual predictions. The goal is to show a clear, end-to-end example of the workflow used in class: data loading → quick cleaning → modeling → evaluation → simple decision support. The code is intentionally short and readable so it can serve as a learning reference. No confidential data is used.

Key features

Explore tab: summaries, histogram, boxplot by target

Model tab: coefficients and model summary

Evaluate tab: AUC, ROC curve, error rate

Predict tab: user inputs → default probability + simple risk label

Lightweight stack (Shiny, ggplot2, dplyr, readr, pROC, DT)
