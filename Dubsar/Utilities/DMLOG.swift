/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

func DMLOG(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Trace, message: message)
        #else
    #endif
}

func DMTRACE(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Trace, message: message)
        #else
    #endif
}

func DMDEBUG(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Debug, message: message)
        #else
    #endif
}

func DMINFO(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Info, message: message)
        #else
    #endif
}

func DMWARN(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Warn, message: message)
        #else
    #endif
}

func DMERROR(message: String) {
    #if DEBUG
        DubsarModelsLogger.logLevel(.Error, message: message)
        #else
    #endif
}