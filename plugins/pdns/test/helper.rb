DOMAINS_TABLE = <<-SQL
CREATE TABLE `domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `master` varchar(128) DEFAULT NULL,
  `last_check` int(11) DEFAULT NULL,
  `type` varchar(6) NOT NULL,
  `notified_serial` int(11) DEFAULT NULL,
  `account` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_index` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=97 DEFAULT CHARSET=latin1
SQL

RECORDS_TABLE = <<-SQL
CREATE TABLE `records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(6) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `prio` int(11) DEFAULT NULL,
  `change_date` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `rec_name_index` (`name`),
  KEY `nametype_index` (`name`,`type`),
  KEY `domain_id` (`domain_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5967 DEFAULT CHARSET=latin1
SQL

ZONES_TABLE = <<-SQL
CREATE TABLE `zones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) NOT NULL DEFAULT '0',
  `owner` int(11) NOT NULL DEFAULT '0',
  `comment` varchar(1024) DEFAULT '0',
  `zone_templ_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=latin1
SQL

module PDNSHelper
  def self.set_up
    unless ENV['PDNS_DESTRUCTIVE'] == 'true'
      raise 'Please set PDNS_DESTRUCTIVE=true to confirm you know what you are doing.'
    end

    mysql = create_client
    mysql.query(DOMAINS_TABLE)
    mysql.query(RECORDS_TABLE)
    mysql.query(ZONES_TABLE)
    mysql.close
  end

  def self.tear_down
    mysql = create_client
    mysql.query('DROP TABLE domains')
    mysql.query('DROP TABLE records')
    mysql.query('DROP TABLE zones')
    mysql.close
  end

  def self.create_client
    Mysql2::Client.new({
      :host     => Optopus::Plugin::PDNS.plugin_settings['mysql']['hostname'],
      :username => Optopus::Plugin::PDNS.plugin_settings['mysql']['username'],
      :password => Optopus::Plugin::PDNS.plugin_settings['mysql']['password'],
      :database => Optopus::Plugin::PDNS.plugin_settings['mysql']['database']
    })
  end
end
