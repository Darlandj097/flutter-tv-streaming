import re
import psycopg2
import sys

# --- 1. CONFIGURAÇÕES ---

# Caminho para o arquivo M3U
ARQUIVO_M3U = '/app/playlist_253588464_plus.m3u'

# Configurações do PostgreSQL
DB_CONFIG = {
    'host': 'postgres',
    'database': 'tv_multimidia',
    'user': 'tv_user',
    'password': 'tv_password',
    'port': 5432
}


def parse_m3u_for_logo_updates(filepath):
    """
    Lê o arquivo M3U e retorna um dicionário mapeando
    o nome do canal (tvg-name) para a URL do logo (tvg-logo).

    Trata logos vazios ("") como None.
    """
    print(f"Iniciando leitura do arquivo M3U: {filepath}...")
    logo_map = {}
    current_name = None

    try:
        # Tenta abrir com utf-8
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
    except UnicodeDecodeError:
        # Se falhar, tenta com 'latin-1'
        print("Falha no UTF-8, tentando com 'latin-1'...")
        try:
            with open(filepath, 'r', encoding='latin-1') as f:
                content = f.readlines()
        except Exception as e:
            print(f"--- ERRO FATAL AO LER ARQUIVO ---")
            print(f"Não foi possível ler o arquivo: {e}")
            return None
    except FileNotFoundError:
        print(f"--- ERRO FATAL: ARQUIVO NÃO ENCONTRADO ---")
        print(f"Caminho: '{filepath}'")
        return None
    except Exception as e:
        print(f"Ocorreu um erro inesperado ao ler o arquivo: {e}")
        return None

    # Processa as linhas lidas
    for line in content:
        line = line.strip()

        if line.startswith('#EXTINF:'):
            # Reseta para cada nova entrada
            current_name = None
            logo_url = None

            # 1. Extrai o nome (tvg-name ou fallback)
            match_name = re.search(r'tvg-name="(.*?)"', line)
            if match_name:
                current_name = match_name.group(1)
            else:
                try:
                    current_name = line.split(',')[-1]
                except Exception:
                    pass  # Ignora se não conseguir extrair o nome

            if not current_name:
                continue # Pula esta linha se não tiver nome

            # 2. Extrai o logo (tvg-logo)
            match_logo = re.search(r'tvg-logo="(.*?)"', line)
            if match_logo:
                logo_url = match_logo.group(1)

                # --- CORREÇÃO PRINCIPAL ---
                # Se o logo for uma string vazia "", trate como None (NULL no DB)
                if logo_url.strip() == "":
                    logo_url = None

            # Adiciona ao mapa
            logo_map[current_name] = logo_url

    print(f"Leitura concluída. {len(logo_map)} canais mapeados para atualização de logo.")
    return logo_map


def update_channel_logos(db, logo_map):
    """
    Atualiza os logos na tabela 'channels' com base no mapa fornecido.
    """
    if not logo_map:
        print("Nenhum canal no mapa. Nada para atualizar.")
        return

    print("Iniciando atualização dos logos no banco de dados...")
    updated = 0
    not_found = 0
    skipped_no_logo = 0

    total = len(logo_map)

    try:
        with db.cursor() as cursor:
            # Itera sobre o mapa (nome_canal, url_logo)
            for idx, (name, logo_url) in enumerate(logo_map.items(), start=1):

                if logo_url is None:
                    skipped_no_logo += 1
                    # Opcional: Se quiser limpar logos vazios no banco
                    # cursor.execute(
                    #     "UPDATE channels SET logopath = NULL, imageurls = NULL WHERE name = %s",
                    #     (name,)
                    # )
                    continue # Pula se o M3U não tiver logo para este canal

                # Prepara o comando de atualização
                sql_update = """
                    UPDATE channels
                    SET
                        logopath = %s,
                        imageurls = %s
                    WHERE
                        name = %s
                    RETURNING id; -- Retorna o ID se a atualização ocorrer
                """

                cursor.execute(sql_update, (logo_url, logo_url, name))

                # Verifica se a atualização foi bem-sucedida
                result = cursor.fetchone()
                if result:
                    updated += 1
                else:
                    not_found += 1
                    print(f"AVISO: Canal '{name}' do M3U não foi encontrado no banco.")

                if idx % 100 == 0 or idx == total:
                    print(f"Progresso: {idx}/{total} canais verificados...")

            # Commita todas as atualizações de uma vez
            db.commit()

    except Exception as e:
        print(f"--- ERRO DURANTE A ATUALIZAÇÃO ---")
        print(f"Erro: {e}")
        print("Revertendo (rollback) alterações...")
        db.rollback()

    print("\n--- Resumo da Atualização de Logos ---")
    print(f"Canais atualizados com sucesso: {updated}")
    print(f"Canais do M3U não encontrados no DB: {not_found}")
    print(f"Canais no M3U sem logo (ignorados): {skipped_no_logo}")
    print(f"Total de canais no mapa M3U: {total}")


def main():
    # 1. Conecta ao banco de dados PostgreSQL
    try:
        db = psycopg2.connect(**DB_CONFIG)
        print("Conectado ao banco de dados PostgreSQL.")
    except Exception as e:
        print(f"Erro ao conectar ao PostgreSQL: {e}")
        return

    # 2. Lê e parseia o arquivo M3U para logos
    mapa_de_logos = parse_m3u_for_logo_updates(ARQUIVO_M3U)

    if mapa_de_logos is None:
        print("Falha ao ler o arquivo M3U. Encerrando o script.")
        db.close()
        return

    # 3. Atualiza os logos no banco
    try:
        update_channel_logos(db, mapa_de_logos)
    except Exception as e:
        print(f"Um erro crítico ocorreu durante a atualização: {e}")
    finally:
        # 4. Fecha a conexão
        db.close()
        print("Conexão com o banco de dados fechada.")

    print("\n--- Processo de Atualização de Logos Concluído ---")

# --- Ponto de entrada do script ---
if __name__ == "__main__":
    main()