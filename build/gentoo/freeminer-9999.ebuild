# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-action/minetest/minetest-0.4.10-r2.ebuild,v 1.1 2014/09/25 20:13:59 hasufell Exp $

EAPI=5
inherit eutils cmake-utils gnome2-utils user games git-2

DESCRIPTION="An InfiniMiner/Minecraft inspired game"
HOMEPAGE="http://freeminer.org/"
EGIT_REPO_URI="git://github.com/freeminer/freeminer.git"

LICENSE="LGPL-2.1+ CC-BY-SA-3.0"
SLOT="0"
KEYWORDS=""
IUSE="+curl dedicated luajit nls redis +server +sound +truetype"

RDEPEND="dev-db/sqlite:3
	sys-libs/zlib
	=dev-libs/msgpack-0.5.9
	net-libs/enet
	curl? ( net-misc/curl )
	>=dev-games/irrlicht-1.8-r2
	dev-libs/leveldb
	!dedicated? (
		app-arch/bzip2
		media-libs/libpng:0
		virtual/jpeg
		virtual/opengl
		x11-libs/libX11
		x11-libs/libXxf86vm
		sound? (
			media-libs/libogg
			media-libs/libvorbis
			media-libs/openal
		)
		truetype? ( media-libs/freetype:2 )
	)
	luajit? ( dev-lang/luajit:2 )
	nls? ( virtual/libintl )
	redis? ( dev-libs/hiredis )"
DEPEND="${RDEPEND}
	>=dev-games/irrlicht-1.8-r2
	nls? ( sys-devel/gettext )"

pkg_setup() {
	games_pkg_setup

	if use server || use dedicated ; then
		enewuser ${PN} -1 -1 /var/lib/${PN} ${GAMES_GROUP}
	fi
}

src_unpack() {
	git-2_src_unpack
}

src_prepare() {
#	epatch \
#		"${FILESDIR}"/${P}-as-needed.patch \
#		"${FILESDIR}"/${P}-shared-irrlicht.patch \


	# correct gettext behavior
	if [[ -n "${LINGUAS+x}" ]] ; then
		for i in $(cd po ; echo *) ; do
			if ! has ${i} ${LINGUAS} ; then
				rm -r po/${i} || die
			fi
		done
	fi

	# jthread is modified
	# json is modified
	# rm -r src/sqlite || die

	# set paths
	sed \
		-e "s#@BINDIR@#${GAMES_BINDIR}#g" \
		-e "s#@GROUP@#${GAMES_GROUP}#g" \
		"${FILESDIR}"/freeminerserver.confd > "${T}"/freeminerserver.confd || die
	}
CMAKE_BUILD_TYPE="Release"
#CMAKE_IN_SOURCE_BUILD="1"
src_configure() {
	 local mycmakeargs=(
		$(usex dedicated "-DBUILD_SERVER=ON -DBUILD_CLIENT=OFF" "$(cmake-utils_use_build server SERVER) -DBUILD_CLIENT=ON")
		-DCUSTOM_BINDIR="${GAMES_BINDIR}"
		-DCUSTOM_DOCDIR="/usr/share/doc/${PF}"
		-DCUSTOM_LOCALEDIR="/usr/share/locale"
		-DCUSTOM_SHAREDIR="${GAMES_DATADIR}/${PN}"
		$(cmake-utils_use_enable curl CURL)
		$(cmake-utils_use_enable truetype FREETYPE)
		$(cmake-utils_use_enable nls GETTEXT)
		-DENABLE_GLES=0
		$(cmake-utils_use_enable redis REDIS)
		$(cmake-utils_use_enable sound SOUND)
		$(cmake-utils_use !luajit DISABLE_LUAJIT)
		-DRUN_IN_PLACE=0
		$(use dedicated && {
			echo "-DIRRLICHT_SOURCE_DIR=/the/irrlicht/source"
			echo "-DIRRLICHT_INCLUDE_DIR=/usr/include/irrlicht"
		})
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install

	if use server || use dedicated ; then
		newinitd "${FILESDIR}"/freeminerserver.initd freeminer-server
		newconfd "${T}"/freeminerserver.confd freeminer-server
	fi

	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	gnome2_icon_cache_update

	if ! use dedicated ; then
		elog
		elog "optional dependencies:"
		elog "	games-action/freeminer_default (official mod)"
		elog
	fi

	if use server || use dedicated ; then
		elog
		elog "Configure your server via /etc/conf.d/freeminer-server"
		elog "The user \"minetest\" is created with /var/lib/${PN} homedir."
		elog "Default logfile is ~/freeminer-server.log"
		elog
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}
