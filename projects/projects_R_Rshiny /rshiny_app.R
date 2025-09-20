# Chargement des packages
library(shiny)
library(ggplot2)
library(dplyr)
library(readxl)
library(pROC)
library(shinythemes)
library(bslib)
library(plotly)
library(DT)
library(shinyjs)

# Chargement des données
df <- read_excel("C:\\Users\\hanil\\Desktop\\Dossier SHINY\\test\\default_of_credit_card_clients.xls", skip = 1)
df <- df %>%
  rename(default = `default payment next month`) %>%
  select(-ID) %>%
  filter(EDUCATION %in% c(1, 2, 3, 4))

# Dictionnaires de valeurs
education_labels <- c("0" = "Inconnu", "1" = "Supérieur", "2" = "Université", "3" = "Lycée", "4" = "Autres")
marriage_labels <- c("0" = "Inconnu", "1" = "Marié(e)", "2" = "Célibataire", "3" = "Autres")

# Modèle
set.seed(123)
train_index <- sample(1:nrow(df), 0.7 * nrow(df))
train <- df[train_index, ]
test <- df[-train_index, ]
model <- glm(default ~ ., data = train, family = "binomial")
probs <- predict(model, newdata = test, type = "response")
auc_value <- auc(test$default, probs)
pred_classes <- ifelse(probs > 0.5, 1, 0)
error_rate <- mean(pred_classes != test$default)

# UI
ui <- fluidPage(
  useShinyjs(),
  theme = bs_theme(
    bootswatch = "minty",
    primary = "#ffe5b4",
    base_font = font_google("Source Sans Pro"),
    heading_font = font_google("Merriweather"),
    font_scale = 1.1
  ),
  
  tags$head(
    tags$style(HTML("
      .navbar { font-size: 18px; }
      .navbar-default .navbar-nav > .active > a {
        background-color: #fce4ec !important;
        color: white !important;
        box-shadow: inset 0 -3px 0 #ec407a;
      }
      .client-card {
        border: 3px solid #48c9b0;
        padding: 20px;
        border-radius: 15px;
        background: linear-gradient(135deg, #fef9e7, #e8f8f5);
        box-shadow: 0 0 10px rgba(0,0,0,0.1);
        color: #2c3e50;
        font-size: 16px;
      }
      h1 { font-family: 'Merriweather'; font-size: 42px; text-align:center; color: #48c9b0; }
      h4 { color: #2874a6; }
    "))
  ),
  
  h1("Évaluation du Risque Crédit Client"),
  
  navbarPage("",
             tabPanel(" Accueil",
                      fluidRow(
                        column(12,
                               div(style = "padding: 30px;",
                                   h2("Bienvenue chers client(e)s ! "),
                                   p("L'objectif de cette application est d'estimer votre probabilité de défaut de paiement à l'aide d'un modèle de régression logistique ( à partir du jeu de données : Default Payments of Credit Card (Taiwan))"),
                                   h4("Vous pourrez retrouver dans nos différents onglets:"),
                                   tags$ul(
                                     tags$li("Exploration des données"),
                                     tags$li("Présentation et modélisation"),
                                     tags$li("Évaluation des performances"),
                                     tags$li("Prédiction personnalisée")
                                   )
                               ),
                        )
                      )
             ),
             
             tabPanel(" 🔹 Exploration",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("var", "Choisir une variable :", choices = names(df))
                        ),
                        mainPanel(
                          h4("Type de variable sélectionnée :"), textOutput("varType"),
                          h4("Statistiques descriptives"), verbatimTextOutput("summaryStats"),
                          h4("Visualisations"),
                          fluidRow(
                            column(6, h5("⟶ Histogramme"), plotlyOutput("histPlot")),
                            column(6, h5("⟶Boxplot vs défaut"), plotlyOutput("boxPlot"))
                          ),
                          h4("Corrélation avec la variable cible"), textOutput("correlationText")
                        )
                      )
             ),
             
             tabPanel("🔸  Présentation et modélisation",
                      fluidRow(
                        column(12,
                               div(style = "border: 2px solid #e3e3e3; border-radius: 12px; padding: 25px; background-color: #fdfdfd; box-shadow: 0 2px 6px rgba(0,0,0,0.05); margin-bottom: 20px;",
                                   h3(" Qu’est-ce qu’un modèle de régression logistique ?"),
                                   p("Un modèle de régression logistique est un outil statistique utilisé pour prédire la probabilité qu'un événement se produise ou non. Dans le domaine du scoring, cet outil permet d'analyser la fiabilité d'un client ou d'un emprunteur afin d'évaluer son niveau de risque.")
                               )
                        )
                      ),
                      fluidRow(
                        column(6, h4("Coefficients estimés"), tableOutput("coeffTable")),
                        column(6,
                               h4( "Interprétation complète"),
                               verbatimTextOutput("modelSummary"),
                               htmlOutput("interpretationText")
                        )
                      )
             ),
             
             tabPanel("🔹  Évaluation des performances",
                      fluidRow(
                        column(12,
                               h3("Analyse de performance du modèle"),
                               p("Cet onglet vous permet d’évaluer la qualité prédictive du modèle.")
                        )
                      ),
                      br(),
                      fluidRow(
                        column(4, align = "center",
                               actionButton("rocBtn", "📉 Afficher la courbe ROC", class = "btn btn-primary"),
                               br(), br(),
                               plotOutput("rocCurve", height = "300px")
                        ),
                        column(4, align = "center",
                               actionButton("aucBtn", "Voir le score AUC", class = "btn btn-primary"),
                               br(),
                               div(style = "margin-top: 15px; font-size: 16px; color: #2c3e50; font-weight: bold;",
                                   textOutput("aucText"))
                        ),
                        column(4, align = "center",
                               actionButton("errBtn", "⚠Calculer le taux d'erreur", class = "btn btn-warning"),
                               br(),
                               uiOutput("errorBox")
                        )
                      )
             ),
             
             tabPanel("🔸 Votre prédiction personnnalisée",
                      fluidRow(
                        column(4,
                               wellPanel(
                                 textInput("prenom", "Prénom :", value = ""),
                                 textInput("nom", "Nom :", value = ""),
                                 numericInput("age", "Âge", value = 35),
                                 numericInput("limit", "Montant du crédit (LIMIT_BAL)", value = 100000),
                                 selectInput("sex", "Sexe", choices = c("Homme" = 1, "Femme" = 2)),
                                 selectInput("education", "Éducation", choices = setNames(names(education_labels), education_labels[1:4])),
                                 selectInput("marriage", "État civil", choices = setNames(names(marriage_labels), marriage_labels)),
                                 
                                 
                                 sliderInput("PAY_0", "Statut du remboursement en avril 2005 (PAY_0)", min = -2, max = 8, value = 0),
                                 sliderInput("PAY_2", "Statut du remboursement en mai 2005 (PAY_2)", min = -2, max = 8, value = 0),
                                 sliderInput("PAY_3", "Statut du remboursement en juin 2005 (PAY_3)", min = -2, max = 8, value = 0),
                                 sliderInput("PAY_4", "Statut du remboursement en juillet 2005 (PAY_4)", min = -2, max = 8, value = 0),
                                 sliderInput("PAY_5", "Statut du remboursement en août 2005 (PAY_5)", min = -2, max = 8, value = 0),
                                 sliderInput("PAY_6", "Statut du remboursement en septembre 2005 (PAY_6)", min = -2, max = 8, value = 0),
                                 
                                 
                                 numericInput("BILL_AMT1", "Montant des factures mensuelles en septembre 2005 (BILL_AMT1)", value = 0),
                                 numericInput("BILL_AMT2", "Montant des factures mensuelles en août 2005 (BILL_AMT2)", value = 0),
                                 numericInput("BILL_AMT3", "Montant des factures mensuelles en juillet 2005 (BILL_AMT3)", value = 0),
                                 numericInput("BILL_AMT4", "Montant des factures mensuelles en juin 2005 (BILL_AMT4)", value = 0),
                                 numericInput("BILL_AMT5", "Montant des factures mensuelles en mai 2005 (BILL_AMT5)", value = 0),
                                 numericInput("BILL_AMT6", "Montant des factures mensuelles en avril 2005 (BILL_AMT6)", value = 0),
                                 
                                 
                                 numericInput("PAY_AMT1", "Montant payé au mois de septembre 2005 (PAY_AMT1)", value = 0),
                                 numericInput("PAY_AMT2", "Montant payé au mois d’août 2005 (PAY_AMT2)", value = 0),
                                 numericInput("PAY_AMT3", "Montant payé au mois de juillet 2005 (PAY_AMT3)", value = 0),
                                 numericInput("PAY_AMT4", "Montant payé au mois de juin 2005 (PAY_AMT4)", value = 0),
                                 numericInput("PAY_AMT5", "Montant payé au mois de mai 2005 (PAY_AMT5)", value = 0),
                                 numericInput("PAY_AMT6", "Montant payé au mois d’avril 2005 (PAY_AMT6)", value = 0),
                                 
                                 actionButton("predictBtn", "Prédire", class = "btn btn-success")
                               )
                        ),
                        column(8,
                               hidden(div(id = "ficheClient", class = "client-card", htmlOutput("scoreOutputStyled")))
                        )
                      )
             ),
             
             tabPanel("🔹 Données complètes",
                      fluidRow(
                        column(12, DTOutput("table"))
                      )
             )
  )
)

#SERVER

server <- function(input, output, session) {
  
  output$varType <- renderText({
    if (input$var == "default") "Variable cible (à prédire)"
    else "Variable explicative"
  })
  
  output$summaryStats <- renderPrint({
    summary(df[[input$var]])
  })
  
  output$histPlot <- renderPlotly({
    if (is.numeric(df[[input$var]])) {
      p <- ggplot(df, aes_string(x = input$var, fill = "factor(default)")) +
        geom_histogram(bins = 30, position = "dodge", alpha = 0.7) +
        labs(fill = "Défaut")
      ggplotly(p)
    }
  })
  
  output$boxPlot <- renderPlotly({
    if (is.numeric(df[[input$var]])) {
      p <- ggplot(df, aes_string(x = "factor(default)", y = input$var, fill = "factor(default)")) +
        geom_boxplot(alpha = 0.7) +
        labs(x = "Défaut")
      ggplotly(p)
    }
  })
  
  output$correlationText <- renderText({
    if (is.numeric(df[[input$var]]) && input$var != "default") {
      cor_val <- cor(df[[input$var]], df$default, use = "complete.obs")
      paste("Corrélation avec la variable cible :", round(cor_val, 3))
    } else {
      "Corrélation non applicable."
    }
  })
  
  output$modelSummary <- renderPrint({
    summary(model)
  })
  
  output$interpretationText <- renderUI({
    coefs <- summary(model)$coefficients
    sig_coefs <- coefs[coefs[, 4] < 0.05, ]
    inc_risk <- rownames(sig_coefs)[sig_coefs[, 1] > 0 & rownames(sig_coefs) != "(Intercept)"]
    dec_risk <- rownames(sig_coefs)[sig_coefs[, 1] < 0 & rownames(sig_coefs) != "(Intercept)"]
    
    HTML(paste0(
      "<div style='display: flex; gap: 40px;'>",
      "<div><h5 style='color:#c0392b;'>🔺 Variables augmentant le risque</h5><ul>",
      paste0("<li><strong>", inc_risk, "</strong></li>", collapse = ""),
      "</ul></div>",
      "<div><h5 style='color:#27ae60;'>🔻 Variables réduisant le risque</h5><ul>",
      paste0("<li><strong>", dec_risk, "</strong></li>", collapse = ""),
      "</ul></div>",
      "</div>",
      "<p style='margin-top:15px;'>Seules les variables <strong>significatives</strong> (p-value &lt; 0.05) sont affichées.</p>"
    ))
  })
  
  output$coeffTable <- renderTable({
    coefs <- summary(model)$coefficients
    data.frame(
      Variable = rownames(coefs),
      Estimate = round(coefs[,1], 3),
      `Std.Error` = round(coefs[,2], 3),
      `z-value` = round(coefs[,3], 2),
      `p-value` = round(coefs[,4], 4)
    )
  })
  
  output$table <- renderDT({
    datatable(df, options = list(pageLength = 10))
  })
  
  observeEvent(input$rocBtn, {
    output$rocCurve <- renderPlot({
      roc_obj <- roc(test$default, probs)
      
      plot(
        roc_obj,
        col = "#2E86C1",         
        lwd = 3,                 
        legacy.axes = TRUE,     
        main = "Courbe ROC",     
        cex.main = 1.5,
        cex.axis = 1.2,
        cex.lab = 1.2
      )
      
      abline(a = 0, b = 1, lty = 2, col = "gray60") 
    })
    output$aucText <- renderText({ "" })
    output$errorBox <- renderUI({ NULL })
  })
  
  observeEvent(input$aucBtn, {
    output$rocCurve <- renderPlot({ NULL })
    output$aucText <- renderText({
      paste("Score AUC du modèle :", round(auc_value, 3), " Plus proche de 1, meilleur est le modèle.")
    })
    output$errorBox <- renderUI({ NULL })
  })
  
  observeEvent(input$errBtn, {
    output$rocCurve <- renderPlot({ NULL })
    output$aucText <- renderText({ "" })
    
    color <- if (error_rate <= 0.2) {
      "#58d68d"
    } else if (error_rate <= 0.4) {
      "#f5b041"
    } else {
      "#ec7063"
    }
    
    comment <- if (error_rate <= 0.2) {
      "Faible taux d'erreur, Excellent modèle."
    } else if (error_rate <= 0.4) {
      "Taux d'erreur modéré, Modèle acceptable."
    } else {
      "Taux d'erreur élevé, Modèle à améliorer."
    }
    
    output$errorBox <- renderUI({
      div(class = "performance-box", style = paste0("background-color:", color, ";"),
          paste0("Taux d'erreur : ", round(error_rate * 100, 2), "% — ", comment)
      )
    })
  })
  
  observeEvent(input$predictBtn, {
    req(input$prenom, input$nom)
    
    newdata <- data.frame(
      LIMIT_BAL = input$limit,
      SEX = as.numeric(input$sex),
      EDUCATION = as.numeric(input$education),
      MARRIAGE = as.numeric(input$marriage),
      AGE = input$age,
      
      PAY_0 = input$PAY_0,
      PAY_2 = input$PAY_2,
      PAY_3 = input$PAY_3,
      PAY_4 = input$PAY_4,
      PAY_5 = input$PAY_5,
      PAY_6 = input$PAY_6,
      
      BILL_AMT1 = input$BILL_AMT1,
      BILL_AMT2 = input$BILL_AMT2,
      BILL_AMT3 = input$BILL_AMT3,
      BILL_AMT4 = input$BILL_AMT4,
      BILL_AMT5 = input$BILL_AMT5,
      BILL_AMT6 = input$BILL_AMT6,
      
      PAY_AMT1 = input$PAY_AMT1,
      PAY_AMT2 = input$PAY_AMT2,
      PAY_AMT3 = input$PAY_AMT3,
      PAY_AMT4 = input$PAY_AMT4,
      PAY_AMT5 = input$PAY_AMT5,
      PAY_AMT6 = input$PAY_AMT6
    )
    
    
    prob <- predict(model, newdata = newdata, type = "response")[1]
    score_lin <- predict(model, newdata = newdata, type = "link")[1]
    
    # Classification
    classe <- case_when(
      prob < 0.1 ~ "A+++",
      prob >= 0.1 & prob < 0.3 ~ "A++",
      prob >= 0.3 & prob < 0.5 ~ "A+",
      prob >= 0.5 & prob < 0.7 ~ "A-",
      TRUE ~ "A--"
    )
    
    
    interpretation <- case_when(
      classe == "A+++" ~ "Excellent client",
      classe == "A++"  ~ "Très bon client",
      classe == "A+"   ~ "Bon client",
      classe == "A-"   ~ "Mauvais payeur",
      TRUE             ~ "Très mauvais payeur"
    )
    
    # Couleur selon classification
    couleur <- if (classe %in% c("A-", "A--")) {
      "#f9e79f"  # Orange clair
    } else {
      "#d5f5e3"  # Vert clair
    }
    
    output$scoreOutputStyled <- renderUI({
      HTML(paste0(
        "<div style='padding:20px; border-radius:10px; background-color:", couleur, "; box-shadow:0 0 10px rgba(0,0,0,0.1);'>",
        "<h4><strong>Résultat de l'évaluation pour ", input$prenom, " ", input$nom, "</strong></h4>",
        "<p><strong>Score linéaire estimé :</strong> ", round(score_lin, 3), "</p>",
        "<p><strong>Probabilité de défaut :</strong> ", round(prob * 100, 2), "%</p>",
        "<p><strong>Classification :</strong> ", classe, "</p>",
        "<p><em>Le score de ", input$prenom, " ", input$nom, " est de ", round(score_lin, 3),
        ", soit une probabilité de ", round(prob * 100, 1), "%.</em></p>",
        "<p><strong>", input$prenom, " ", input$nom, "</strong> est un <strong>", interpretation, "</strong>.</p>",
        "</div>"
      ))
    })
    
    shinyjs::show("ficheClient", anim = TRUE)
  })
}


shinyApp(ui, server)

