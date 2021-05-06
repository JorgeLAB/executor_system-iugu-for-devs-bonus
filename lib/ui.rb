class Ui

  class << self
    def introduction
      puts 'Sistema de execução de cobranças'
    end

    def summary
      puts 'Este sistema possibilita a execução de cobranças de um serviço de pagamentos'
      puts '- Realizar download das cobranças pendentes da plataforma de pagamentos'
      puts '- Gerar arquivos TXT de emissão para cada tipo de forma de pagamento'
      puts '- Consultar arquivos de retorno - arquivos de retorno são gerados pelos bancos e administradores de crédito'
      puts '- Validar os arquivos de retorno e enviar os status para a plataforma de pagamentos'
      puts '- Gerar arquivos tipo .PRONTO em caso de execução dos arquivos de retorno'
    end
  end
end
