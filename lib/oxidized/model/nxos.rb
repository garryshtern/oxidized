class NXOS < Oxidized::Model
  prompt /^(\r?[\w.@_()-]+[#]\s?)$/
  comment '! '

  def filter(cfg)
    cfg.gsub! /\r\n?/, "\n"
    cfg.gsub! prompt, ''
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server user (\S+) (\S+) auth (\S+)) (\S+) (priv) (\S+)/, '\\1 <configuration removed> '
    cfg.gsub! /(password \d+) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(radius-server key).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server host .+ key(?: \d+)?) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = filter cfg
    keep = 1
    cfg = cfg.each_line.map do |line|
      # Discard all text between the 1st line describing uptime (inclusive)
      # and the listing of the installed packages (exclusive)
      if line.match(/uptime/i)
        keep = nil
      elsif line.match(/active package/i)
        keep = 1
        line = "\n"+line
      end
      line if keep
    end
    comment cfg.join ""
  end

  cmd 'show inventory all' do |cfg|
    cfg = filter cfg
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = filter cfg
    cfg.gsub! /^(show run.*)$/, '! \1'
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    cfg.gsub! /^[\w.@_()-]+[#].*$/, ''
    cfg
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end
end
