// $Id: perfmon.h,v 1.2 2004-01-03 15:37:42 benkirk Exp $

// The libMesh Finite Element Library.
// Copyright (C) 2002-2004  Benjamin S. Kirk, John W. Peterson
  
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
  
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
  
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA



#ifndef __perfmon_h__
#define __perfmon_h__


// C++ includes
#include <string>
#include <sys/time.h>


// Local includes
#include "libmesh_common.h"

#ifdef HAVE_PAPI_H
namespace Papi {
#  include <papi.h>
}
#endif



class PerfMon
{
 public:
  PerfMon  (std::string id,
	    const unsigned int v=1,
	    const unsigned int pid=0);
	    
  ~PerfMon ();
  void reset ();
  double print (std::string msg="NULL");
  
 private:

  const std::string id_string;
  
  struct timeval the_time_start;
  struct timeval the_time_stop;

  const unsigned int verbose;
  const unsigned int proc_id;

#ifdef HAVE_PAPI_H
  float rtime, ptime, mflops;
  long long int flpins;
#endif
};



inline
void
PerfMon::reset ()
{
  gettimeofday (&the_time_start, NULL);

#ifdef HAVE_PAPI_H
  Papi::PAPI_flops (&rtime, &ptime, &flpins, &mflops);
#endif  
}



inline
double
PerfMon::print (std::string msg)
{  
  gettimeofday (&the_time_stop, NULL);
  
#ifdef HAVE_PAPI_H
  Papi::PAPI_flops (&rtime, &ptime, &flpins, &mflops);
#endif

  const double elapsed_time = ((double) (the_time_stop.tv_sec - the_time_start.tv_sec)) +
                              ((double) (the_time_stop.tv_usec - the_time_start.tv_usec))/1000000.;

  if (verbose)
    {
      
      if (proc_id == 0)
	{
	  if (msg == "NULL")
	    std::cout << " " << id_string
		      << ": elapsed time: "
		      << elapsed_time << " (sec)"
		      << std::endl;
	  else
	    std::cout << " " << msg
		      << ": elapsed time: "
		      << elapsed_time << " (sec)"
		      << std::endl;
	  
#ifdef HAVE_PAPI_H
	  if (msg == "NULL")
	    std::cout << " " << id_string
		      << ": mflops: "
		      << mflops
		      << std::endl;
	  else
	    std::cout << " " << msg
		      << ": mflops: "
		      << mflops
		      << std::endl;
      
#endif

	}
    }
  
  return elapsed_time;
}


inline
PerfMon::PerfMon (std::string id,
		  const unsigned int v,
		  const unsigned int pid) :
  id_string(id),
  verbose(v),
  proc_id(pid)
{
  reset ();
}



inline
PerfMon::~PerfMon ()
{
  print ();
}





#endif