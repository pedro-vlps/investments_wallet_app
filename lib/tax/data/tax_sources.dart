class TaxSource {
  const TaxSource(this.title, this.url, this.fingerprint);
  final String title;
  final String url;
  final String fingerprint;
}

const taxSources = <TaxSource>[
  TaxSource(
    "Bolsa de Valores",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/bolsa-de-valores/",
    "edc2d1cbddb32563a450706f418d92a29be6976f8a72a660032cab44676c955a",
  ),
  TaxSource(
    "Isenções",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/isencoes",
    "ad74792db447082b379dbb22ae39955f9b0eba6b0f6806faa6c2f84d00d5d077",
  ),
  TaxSource(
    "Compensações",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/compensacoes",
    "ae0935e734e7b26a0c2b81f09198868b535bf910c47fb39efe314e8c7e896ce3",
  ),
  TaxSource(
    "Retenções",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/retencoes",
    "11114a7f5d94693ef80db804a8c5e0d27d144d88192b0b9be849c15f6c9f147d",
  ),
  TaxSource(
    "Cálculo e pagamento",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/calculo-e-pagamento-do-imposto",
    "1da040173e141706b512bb9f53eba2a447c68da9ce808693bea8587ba26a6cc4",
  ),
  TaxSource(
    "Manual ReVar",
    "https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/manual",
    "3f6566479c358a6a1ea6b0c127e87b375f3f58a003394f2a79e21305feb5fa31",
  ),
  TaxSource(
    "Prazo anual",
    "https://www.gov.br/receitafederal/pt-br/acesso-a-informacao/perguntas-frequentes/imposto-de-renda/dirpf/declaracao/prazo",
    "ee211b7e7f24a81421de6ab5c7e4d760e2b12b19996a048efb682e683d134287",
  ),
  TaxSource(
    "Dividendos em 2026",
    "https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2026/agosto/receita-federal-orienta-sobre-os-procedimentos-para-o-recolhimento-do-imposto-de-renda-retido-na-fonte-sobre-lucros-e-dividendos/",
    "a5ff30209442f68115cc86108e2474724692f7f7fd367d907b26278cbd2dcb9e",
  ),
];
