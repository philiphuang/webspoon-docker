FROM tomcat:9-jdk8
MAINTAINER Hiromu Hota <hiromu.hota@hal.hitachi.com>
ENV JAVA_OPTS="-Xms1024m -Xmx2048m"
RUN rm -rf ${CATALINA_HOME}/webapps/* \
    && mkdir ${CATALINA_HOME}/webapps/ROOT \
    && echo "<% response.sendRedirect(\"spoon\"); %>" > ${CATALINA_HOME}/webapps/ROOT/index.jsp

# check PDI-client version at https://sourceforge.net/projects/pentaho/files/
# check webspoon version at https://github.com/HiromuHota/pentaho-kettle/releases
# check mysql connector-j version at https://dev.mysql.com/doc/index-connectors.html
ARG pdi_ver_main=9.3
ARG pdi_ver_full=9.3.0.0-428
ARG base=9.0
ARG patch=22
ARG version=0.$base.$patch
ARG dist=9.0.0.0-423

RUN groupadd -r tomcat \
    && useradd -r --create-home -g tomcat tomcat \
    && chown -R tomcat:tomcat ${CATALINA_HOME}
# tomcat9-jdk8底包去除了unzip，需要补上
RUN apt-get update  && \
    apt-get install --assume-yes unzip && \
    apt-get clean autoclean  && \
    apt-get autoremove -y  && \
    rm -rf /var/lib/apt/lists/*

USER tomcat
RUN wget -q https://sourceforge.net/projects/pentaho/files/Pentaho-${pdi_ver_main}/client-tools/pdi-ce-${pdi_ver_full}.zip  && \
  unzip -q pdi-ce-${pdi-ver-full}.zip && \
  mv data-integration/system ${CATALINA_HOME}/system && \
  mv data-integration/plugins ${CATALINA_HOME}/plugins && \
  mv data-integration/simple-jndi ${CATALINA_HOME}/simple-jndi && \
  mv data-integration/samples ${CATALINA_HOME}/samples && \
  mv data-integration/LICENSE.txt ${CATALINA_HOME}/webSpoon-LICENSE.txt && \
  rm pdi-ce-${pdi-ver-full}.zip && \
  rm -rf data-integration

ARG CACHEBUST=1

RUN echo "org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true" | tee -a conf/catalina.properties
COPY --chown=tomcat:tomcat install.sh /tmp/install.sh
RUN sh /tmp/install.sh

ADD --chown=tomcat:tomcat https://github.com/HiromuHota/pentaho-kettle/releases/download/webspoon%2F$version/webspoon-security-$dist-$patch.jar ${CATALINA_HOME}/lib/
RUN echo "CLASSPATH="$CATALINA_HOME"/lib/webspoon-security-$dist-$patch.jar" | tee ${CATALINA_HOME}/bin/setenv.sh
COPY --chown=tomcat:tomcat catalina.policy ${CATALINA_HOME}/conf/
RUN mkdir -p $HOME/.kettle/users && mkdir -p $HOME/.pentaho/users
RUN mkdir -p $HOME/.kettle/data && cp -r ${CATALINA_HOME}/samples $HOME/.kettle/data/samples
