-- exportar_dados.sql
SET client_encoding TO 'UTF8';

\echo '>> A exportar dados completos (com dependentes e historico)...'

-- O comando \copy tem de ser TUDO numa linha so. Nao quebres esta linha:
\copy (SELECT json_build_object('id_fun_sql', f.id_fun, 'nome_completo', f.primeiro_nome || ' ' || f.ultimo_nome, 'nif', f.nif, 'email', f.email, 'cargo_atual', f.cargo, 'contactos', json_build_object('telemovel', f.num_telemovel, 'morada', json_build_object('rua', f.nome_rua, 'localidade', f.nome_localidade, 'cp', f.codigo_postal)), 'dependentes', COALESCE((SELECT json_agg(json_build_object('nome', d.nome, 'parentesco', d.parentesco, 'data_nascimento', d.data_nascimento, 'sexo', d.sexo)) FROM bd054_schema.dependentes d WHERE d.id_fun = f.id_fun), '[]'::json), 'historico_profissional', COALESCE((SELECT json_agg(json_build_object('empresa', h.nome_empresa, 'cargo', h.cargo, 'data_inicio', h.data_inicio, 'data_fim', h.data_fim)) FROM bd054_schema.historico_empresas h WHERE h.id_fun = f.id_fun), '[]'::json)) FROM bd054_schema.funcionarios f) TO 'dados_final.json';