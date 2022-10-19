---
layout: post
title: "Usando feature flags do gitlab em uma aplicação Java multi-tenant"
author: "Jefferson Quesado"
tags: java gitlab devops feature-flags engenharia-de-software
base-assets: "/assets/feature-flags-unleash-multi-tenant-java-gitlab/"
---

O foco aqui é explorar o uso de feature flags do [Unleashed](https://getunleash.io/)
em uma aplicação Java/GWT. A aplicação em si é multi-tenant, e por negócio a intenção
é ligar e desligar a feature flag no tenant como um todo neste primeiro momento.