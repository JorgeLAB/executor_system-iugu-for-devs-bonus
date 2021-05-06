require 'spec_helper'

describe 'User interface' do
	describe 'introduction system' do
    it '.introduction' do
      expect do
        Ui.introduction
      end.to output("Sistema de execução de cobranças\n").to_stdout
  	end

    it '.summary' do

      system_features = "Este sistema possibilita a execução de cobranças de um serviço de pagamentos\n"\
                         "- Realizar download das cobranças pendentes da plataforma de pagamentos\n"\
                         "- Gerar arquivos TXT de emissão para cada tipo de forma de pagamento\n"\
                         "- Consultar arquivos de retorno - arquivos de retorno são gerados pelos bancos e administradores de crédito\n"\
                         "- Validar os arquivos de retorno e enviar os status para a plataforma de pagamentos\n"\
                         "- Gerar arquivos tipo .PRONTO em caso de execução dos arquivos de retorno\n"

      expect do
        Ui.summary
      end.to output(system_features).to_stdout
    end

    it '.login' do

    end
  end
end
