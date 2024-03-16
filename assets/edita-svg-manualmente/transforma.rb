# frozen_string_literal: true

linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []
lendoPath = false

for linha in linhas do
    linha = linha.strip
    if lendoPath then
        if linha.start_with? '"' then
            lendoPath = false
            novas_linhas.append(linha)
        else
            linha_transformada = linha[0] + linha[1..].split(" ").map do |l|
                l.to_f * (16.0/27.0)
            end.join(" ")
            novas_linhas.append(linha_transformada)
        end
    else
        if linha.end_with? 'd="' then
            lendoPath = true
        end
        novas_linhas.append(linha)
    end
end

# tratando a primeira linha
novas_linhas[0] = novas_linhas[0].sub("0 0 27 27", "0 0 16 16")
puts novas_linhas.join