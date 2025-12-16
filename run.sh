#!/bin/bash -e

export PATH=`pwd`:$PATH
alias mvnw=mvn

read -p "Do you want to delete ~/.m2/repository - are you sure! (y)" SURE
if [ "$SURE" = "y" ]; then
  rm -rf ~/.m2/repository
fi
 
OUTPUTFILE=`pwd`/run.out

read -p "Do you want to build dependencies? (y)" SURE
if [ "$SURE" = "y" ]; then
  read -p "This is going to reset files that are not committed - are you sure! (y)" SURE
  if [ "$SURE" != "y" ]; then
    exit
  fi

  [ ! -d jboss-modules ] && git clone -b 2.1-wildfly_graal_elytron_services git@github.com:jfdenise/jboss-modules
  [ ! -d jboss-vfs ] && git clone -b archive_servlet_starting git@github.com:jfdenise/jboss-vfs
  [ ! -d jboss-msc ] && git clone -b archive_servlet_starting git@github.com:jfdenise/jboss-msc
  [ ! -d xnio ] && git clone -b archive_servlet_starting git@github.com:jfdenise/xnio
  [ ! -d undertow ] && git clone -b websocket_continuing git@github.com:jfdenise/undertow
  [ ! -d wildfly-elytron ] && git clone -b wildfly_graal_elytron_services git@github.com:jfdenise/wildfly-elytron
  [ ! -d jboss-remoting ] && git clone -b wildfly_graal_elytron_services git@github.com:jfdenise/jboss-remoting

  cd jboss-modules
  git fetch --all
  git checkout 2.1-wildfly_graal_elytron_services
  git clean -fdx
  git checkout -- .
  git pull --rebase origin 2.1-wildfly_graal_elytron_services
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd jboss-vfs
  git fetch --all
  git checkout archive_servlet_starting
  git clean -fdx
  git checkout -- .
  git pull --rebase upstream archive_servlet_starting
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd jboss-msc
  git fetch --all
  git checkout archive_servlet_starting
  git clean -fdx
  git checkout -- .
  git pull --rebase origin archive_servlet_starting
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd xnio
  git fetch --all
  git checkout archive_servlet_starting
  git clean -fdx
  git checkout -- .
  git pull --rebase upstream archive_servlet_starting
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd undertow
  git fetch --all
  git checkout websocket_continuing
  git clean -fdx
  git checkout -- .
  git pull --rebase origin websocket_continuing
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd wildfly-elytron
  git fetch --all
  git checkout wildfly_graal_elytron_services
  git clean -fdx
  git checkout -- .
  git pull --rebase origin wildfly_graal_elytron_services
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd jboss-remoting
  git fetch --all
  git checkout wildfly_graal_elytron_services
  git clean -fdx
  git checkout -- .
  git pull --rebase origin wildfly_graal_elytron_services
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd jboss-modules; mvn clean install -DskipTests; cd ..
  cd jboss-vfs; mvn clean install -DskipTests; cd ..
  cd jboss-msc; mvn clean install -DskipTests; cd ..
  cd xnio; mvn clean install -DskipTests; cd ..
  cd undertow; mvn clean install -DskipTests; cd ..
  cd wildfly-elytron; mvn clean install -DskipTests -DskipCompatibility=true ; cd ..
  cd jboss-remoting; mvn clean install -DskipTests; cd ..

  cd wildfly-core
  git fetch --all
  git checkout wildfly_graal_elytron_services
  git clean -fdx
  git checkout -- .
  git pull --rebase origin wildfly_graal_elytron_services
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd wildfly
  git fetch --all
  git checkout websocket_continuing
  git clean -fdx
  git checkout -- .
  git pull --rebase origin websocket_continuing
  echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
  git log -1 >> $OUTPUTFILE
  cd ..

  cd wildfly-core; mvn clean install -DskipTests; cd ..
  cd wildfly; mvn clean install -DskipTests; cd ..
fi

# Main project
git fetch --all
git pull --rebase upstream wildfly_graal_elytron_services
echo "`pwd` on `git branch --show-current` and current commit is :"  >> $OUTPUTFILE
git log -1 >> $OUTPUTFILE

export GRAALVM_HOME=`pwd`/graalvm-jdk-25.0.1+8.1/
export JAVA_HOME=${GRAALVM_HOME}
export PATH=${GRAALVM_HOME}/bin:$PATH

cd ../

cd wildfly-graal
cd module-launcher; mvn clean install -DskipTests; cd ..
cd agent; mvn clean install -DskipTests; cd ..
cd wildfly-substitutions;mvn clean install -DskipTests;cd ..

galleon-6.1.1.Final/bin/galleon.sh install wildfly#39.0.0.Beta1-SNAPSHOT --layers=base-server,io,elytron,servlet,logging,core-tools --dir=min-core-server

cp files/logging.properties min-core-server/standalone/configuration
cp -r files/welcome-content min-core-server/

min-core-server/bin/add-user.sh -a -u 'quickstartUser' -p 'quickstartPwd1!' -g Users

cd deployment-src/helloworld;mvn clean install;cd ../..
rm -rf min-core-server/deployment-exploded
unzip deployment-src/helloworld/target/helloworld.war -d min-core-server/deployment-exploded

[ ! -d jspc ] && git clone https://github.com/rmartinc/jspc
cd jspc; mvn clean install -DskipTests; cd ..
cd jspc/tool
mkdir -p precompiled/classes/META-INF
mvn exec:java -Dexec.args="-v -p pre.compiled.jsps -d  precompiled/classes -webapp ../../min-core-server/deployment-exploded -webfrg  precompiled/classes/META-INF/web-fragment.xml"
cd precompiled/classes
jar cvf precompiled-jsp.jar *
mkdir -p ../../../../min-core-server/deployment-exploded/WEB-INF/lib
cp precompiled-jsp.jar ../../../../min-core-server/deployment-exploded/WEB-INF/lib
cd ../../../..

cd deployment-src/custom-module;mvn clean install;cd ../..
