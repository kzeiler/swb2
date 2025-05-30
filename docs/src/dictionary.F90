module dictionary

  use iso_c_binding, only : c_int, c_float, c_double, c_bool
  use constants_and_conversions, only : iTINYVAL, fTINYVAL, TRUE, FALSE
  use exceptions
  use logfiles
  use fstring
  use fstring_list
  use exceptions
  implicit none

  private

  type, public :: DICT_ENTRY_T

    character (len=:), allocatable            :: key
    character (len=:), allocatable            :: secondary_key

    type (FSTRING_LIST_T)                      :: sl
    type (DICT_ENTRY_T), pointer              :: previous   => null()
    type (DICT_ENTRY_T), pointer              :: next       => null()

  contains

    procedure   :: add_key_sub
    generic     :: add_key => add_key_sub

    procedure   :: add_string_sub
    procedure   :: add_integer_sub
    procedure   :: add_float_sub
    procedure   :: add_double_sub
    procedure   :: add_logical_sub
    generic     :: add_value  => add_string_sub,   &
                                 add_integer_sub,  &
                                 add_float_sub,    &
                                 add_double_sub,   &
                                 add_logical_sub
  end type DICT_ENTRY_T


  type, public :: DICT_T

    type (DICT_ENTRY_T), pointer   :: first   => null()
    type (DICT_ENTRY_T), pointer   :: last    => null()
    type (DICT_ENTRY_T), pointer   :: current => null()
    integer (c_int)                :: count   = 0

  contains

    procedure, private   :: get_entry_by_key_fn
    procedure, private   :: get_entry_by_index_fn
    generic              :: get_entry => get_entry_by_key_fn,    &
                                         get_entry_by_index_fn

    procedure, private   :: get_next_entry_by_key_fn
    procedure, private   :: get_next_entry_fn
    generic              :: get_next_entry => get_next_entry_by_key_fn, &
                                              get_next_entry_fn

    procedure, private   :: add_entry_to_dict_sub
    generic              :: add_entry => add_entry_to_dict_sub

    procedure, private   :: key_name_already_in_use_fn
    generic              :: key_already_in_use => key_name_already_in_use_fn

    procedure            :: find_dict_entry_fn
    generic              :: find_dict_entry => find_dict_entry_fn

    procedure, private   :: delete_entry_by_key_sub
    generic              :: delete_entry => delete_entry_by_key_sub

    procedure, private   :: print_all_dictionary_entries_sub
    generic              :: print_all => print_all_dictionary_entries_sub

    procedure, private   :: grep_dictionary_key_names_fn
    generic              :: grep_keys => grep_dictionary_key_names_fn

    procedure, public    :: get_value => get_value_as_string_sub

    procedure, private   :: get_values_as_int_sub
    procedure, private   :: get_values_as_float_sub
    procedure, private   :: get_values_as_logical_sub
    procedure, private   :: get_values_as_string_list_sub
    procedure, private   :: get_values_as_int_given_list_of_keys_sub
    procedure, private   :: get_values_as_float_given_list_of_keys_sub
    procedure, private   :: get_values_as_logical_given_list_of_keys_sub
    procedure, private   :: get_values_as_string_list_given_list_of_keys_sub
    generic              :: get_values => get_values_as_int_sub,                          &
                                          get_values_as_float_sub,                        &
                                          get_values_as_logical_sub,                      &
                                          get_values_as_string_list_sub,                  &
                                          get_values_as_int_given_list_of_keys_sub,       &
                                          get_values_as_float_given_list_of_keys_sub,     &
                                          get_values_as_logical_given_list_of_keys_sub,   &
                                          get_values_as_string_list_given_list_of_keys_sub

  end type DICT_T

  ! CF = "Control File"; this dictionary will be populated elsewhere with all of the
  !                      directives found in the SWB control file.
  type (DICT_T), public                     :: CF_DICT
  type (DICT_ENTRY_T), public, pointer      :: CF_ENTRY

contains

 !!
 !! This section contains methods bound to the DICT_ENTRY_T class
 !!

 subroutine add_key_sub(this, sKey)

    class (DICT_ENTRY_T)            :: this
    character (len=*), intent(in)   :: sKey

     this%key = trim(sKey)

  end subroutine add_key_sub

!--------------------------------------------------------------------------------------------------

  subroutine add_string_sub(this, sValue)

    class (DICT_ENTRY_T)            :: this
    character (len=*), intent(in)   :: sValue

    call this%sl%append(sValue)

  end subroutine add_string_sub

!--------------------------------------------------------------------------------------------------

  subroutine add_float_sub(this, fValue)

    class (DICT_ENTRY_T)             :: this
    real (c_float), intent(in)       :: fValue

    call this%sl%append( asCharacter( fValue ) )

  end subroutine add_float_sub

!--------------------------------------------------------------------------------------------------

  subroutine add_integer_sub(this, iValue)

    class (DICT_ENTRY_T)               :: this
    integer (c_int), intent(in)        :: iValue

    call this%sl%append( asCharacter( iValue ) )

  end subroutine add_integer_sub

!--------------------------------------------------------------------------------------------------

  subroutine add_double_sub(this, dValue)

    class (DICT_ENTRY_T)               :: this
    real (c_double), intent(in)        :: dValue

    call this%sl%append( asCharacter( dValue ) )

  end subroutine add_double_sub

!--------------------------------------------------------------------------------------------------

  subroutine add_logical_sub(this, lValue)

    class (DICT_ENTRY_T)                :: this
    logical (c_bool), intent(in)   :: lValue

    call this%sl%append( asCharacter( lValue ) )

  end subroutine add_logical_sub

!--------------------------------------------------------------------------------------------------

  !!
  !! The methods in the section below are bound to the DICT_T type, which is essentially a
  !! linked list of DICT_ENTRY_T objects
  !!

  function get_entry_by_key_fn(this, sKey)   result( pDict )

    class (DICT_T)                :: this
    character (len=*), intent(in) :: sKey
    type (DICT_ENTRY_T), pointer  :: pDict

    this%current => this%first

    do while ( associated( this%current ) )

      if ( this%current%key .strapprox. sKey )  exit

      this%current => this%current%next

    enddo

    if (.not. associated( this%current ) )  &
      call warn( sMessage="Failed to find a dictionary entry with a key value of "//dquote(sKey),   &
                 iLogLevel=LOG_DEBUG,                                                               &
                 lEcho=FALSE )

    pDict => this%current

  end function get_entry_by_key_fn

!--------------------------------------------------------------------------------------------------

  function get_entry_by_index_fn(this, iIndex)   result( pDict )

    class (DICT_T)                   :: this
    integer (c_int), intent(in)      :: iIndex
    type (DICT_ENTRY_T), pointer     :: pDict

    ! [ LOCALS ]
    integer (c_int)  :: iCurrentIndex

    iCurrentIndex = 1

    this%current => this%first

    do

      if ( .not. associated( this%current ) ) exit

      if ( iCurrentIndex == iIndex )  exit

      this%current => this%current%next

      iCurrentIndex = iCurrentIndex + 1

    enddo

    if (.not. associated( this%current ) )  &
      call warn( sMessage="Failed to find a dictionary entry with a index value of "   &
        //asCharacter(iIndex),                                                         &
                 iLogLevel=LOG_DEBUG,                                                  &
                 lEcho=FALSE )

    pDict => this%current

  end function get_entry_by_index_fn

!--------------------------------------------------------------------------------------------------

  function get_next_entry_by_key_fn(this, sKey)   result( pDict )

    class (DICT_T)                :: this
    character (len=*), intent(in) :: sKey
    type (DICT_ENTRY_T), pointer  :: pDict

    ! if "current" location is not null, it will point to the location of the
    ! last key value found. move forward by one before examining the next key...
    if (associated( this%current) ) pDict => this%current%next

    do while ( associated( pDict ) )

      if ( pDict%key .strequal. sKey )  exit

      pDict => pDict%next
      this%current => pDict

    enddo

    if (.not. associated( pDict ) )  &
      call warn( sMessage="Failed to find another dictionary entry with a key value of "//dquote(sKey),   &
                 iLogLevel=LOG_DEBUG,                                                               &
                 lEcho=FALSE )

  end function get_next_entry_by_key_fn

!--------------------------------------------------------------------------------------------------

  function get_next_entry_fn(this)   result( pDict )

    class (DICT_T)                :: this
    type (DICT_ENTRY_T), pointer  :: pDict

    pDict => null()

    ! if "current" location is not null, it will point to the location of the
    ! last key value found. move forward by one before examining the next key...
    if (associated( this%current) ) then
      pDict => this%current%next
      this%current => this%current%next
    endif

    if (.not. associated( pDict ) )  &
      call warn( sMessage="Reached end of dictionary.",                    &
                 iLogLevel=LOG_DEBUG,                                      &
                 lEcho=FALSE )

  end function get_next_entry_fn

!--------------------------------------------------------------------------------------------------

  function grep_dictionary_key_names_fn(this, sKey)   result( slString )

    class (DICT_T)                   :: this
    character (len=*), intent(in)    :: sKey
    type (FSTRING_LIST_T)             :: slString

    ! [ LOCALS ]
    integer (c_int)             :: iIndex

    this%current => this%first

    do while ( associated(this%current ) )

      if ( this%current%key .containssimilar. sKey )         &
         call slString%append(this%current%key)

      this%current => this%current%next

    enddo

    if ( slString%get(1) == '<NA>' )            &
      call warn(sMessage="Failed to find a dictionary entry associated with a key value of " &
        //dquote(sKey)//".", sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE )

  end function grep_dictionary_key_names_fn

!--------------------------------------------------------------------------------------------------

function key_name_already_in_use_fn(this, sKey)   result( in_use )

  class (DICT_T)                   :: this
  character (len=*), intent(in)    :: sKey
  logical (c_bool)                 :: in_use

  ! [ LOCALS ]
  integer (c_int)             :: iIndex
  integer (c_int)             :: iCount

  this%current => this%first
  iCount = 0

  do while ( associated(this%current ) )

    !iIndex = index(string=this%current%key, substring=asUppercase(sKey) )

    !if ( iIndex > 0 ) iCount = iCount + 1

    if ( this%current%key .strapprox. sKey )  iCount = iCount + 1

    this%current => this%current%next

  enddo

  if ( iCount == 0 ) then

    in_use = FALSE

  else

    in_use = TRUE

  endif

end function key_name_already_in_use_fn


!--------------------------------------------------------------------------------------------------

function find_dict_entry_fn(this, sSearchKey)   result( pDict )

  class (DICT_T)                   :: this
  character (len=*), intent(in)    :: sSearchKey
  type (DICT_ENTRY_T), pointer     :: pDict

  ! [ LOCALS ]
  integer (c_int)             :: iIndex

  pDict => null()
  this%current => this%first

  do while ( associated(this%current ) )

    !iIndex = index(string=this%current%key, substring=asUppercase(sSearchKey) )

    !if ( iIndex > 0 ) then

    if (this%current%key .strapprox. sSearchKey ) then

      pDict => this%current
      exit

    endif

    this%current => this%current%next

  enddo

end function find_dict_entry_fn

!--------------------------------------------------------------------------------------------------

  subroutine add_entry_to_dict_sub(this, dict_entry)

    class (DICT_T)                :: this
    type (DICT_ENTRY_T), pointer  :: dict_entry

    type (DICT_ENTRY_T), pointer  :: temp_dict_entry
    integer (c_int)          :: iIndex

    temp_dict_entry => null()

    if ( associated(dict_entry) ) then

      temp_dict_entry => this%find_dict_entry( dict_entry%key )

      ! the dictionary already contains a dictionary entry with this
      ! key value; append the values to the existing entry
      if ( associated( temp_dict_entry ) ) then

        do iIndex=1, dict_entry%sl%count

          call temp_dict_entry%sl%append( dict_entry%sl%get( iIndex ) )

        enddo

        temp_dict_entry => null()

      else

        this%count = this%count + 1

        if ( associated( this%last) ) then

        ! dictionary has at least one entry

          dict_entry%previous  => this%last
          dict_entry%next      => null()
          this%last%next       => dict_entry
          this%last            => dict_entry
          this%current         => dict_entry

        else  ! this is the first dictionary entry

          this%first => dict_entry
          this%last  => dict_entry
          this%current => dict_entry
          dict_entry%previous => null()
          dict_entry%next     => null()

        endif

      endif

    else

      call warn( sMessage="Internal programming error: dictionary entry is null",   &
          sModule=__FILE__, iLine=__LINE__ )

    endif

  end subroutine add_entry_to_dict_sub

!--------------------------------------------------------------------------------------------------

  subroutine delete_entry_by_key_sub(this, sKey)

    class (DICT_T)                  :: this
    character (len=*), intent(in)   :: sKey

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    type (DICT_ENTRY_T), pointer   :: pTemp

    pTarget => this%get_entry(sKey)

    if ( associated( pTarget ) ) then

      ! first remove object from linked list
      pTemp => pTarget%previous

      if (associated( pTemp) ) then
        ! if pTemp is unassociated, it means we are at the head of the list
        pTemp%next => pTarget%next
        pTarget%next%previous => pTemp

      else

        pTemp => pTarget%next
        this%first => pTemp

      endif

      ! set "current" pointer to entry that was just before the now-deleted entry
      this%current => pTemp

      call pTarget%sl%clear()

    endif

  end subroutine delete_entry_by_key_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_values_as_int_sub(this, sKey, iValues, is_fatal )

    class (DICT_T)                                  :: this
    character (len=*)                               :: sKey
    integer (c_int), allocatable, intent(out)       :: iValues(:)
    logical (c_bool), optional                      :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    pTarget => this%get_entry(sKey)

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key value of "//dquote(sKey),                                  &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      iValues = pTarget%sl%get_integer()

    else

      allocate(iValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to iValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value of "//dquote(sKey), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

      iValues = iTINYVAL

    endif

  end subroutine get_values_as_int_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_values_as_logical_sub(this, sKey, lValues, is_fatal)

    class (DICT_T)                                   :: this
    character (len=*)                                :: sKey
    logical (c_bool), allocatable, intent(out)       :: lValues(:)
    logical (c_bool), optional                       :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    pTarget => this%get_entry(sKey)

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key value of "//dquote(sKey),                                  &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      lValues = pTarget%sl%get_logical()

    else

      allocate(lValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to lValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value of "//dquote(sKey), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

      lValues = FALSE

    endif

  end subroutine get_values_as_logical_sub

!--------------------------------------------------------------------------------------------------

  !> Search through keys for a match; return logical values.
  !!
  !! THis routine allows for multiple header values to be supplied
  !! in the search for the appropriate column.
  !! @param[in]  this  Object of DICT_T class.
  !! @param[in]  slKeys String list containing one or more possible key values to
  !!                    search for.
  !! @param[out] iValues Integer vector of values associated with one of the provided keys.

  subroutine get_values_as_logical_given_list_of_keys_sub(this, slKeys, lValues, is_fatal)

    class (DICT_T)                                     :: this
    type (FSTRING_LIST_T)                               :: slKeys
    logical (c_bool), allocatable, intent(out)         :: lValues(:)
    logical (c_bool), optional                         :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    integer (c_int)           :: iCount
    character (len=:), allocatable :: sText
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    iCount = 0

    do while ( iCount < slKeys%count )

      iCount = iCount + 1

      sText = slKeys%get( iCount)

      pTarget => this%get_entry( sText )

      if ( associated( pTarget ) ) exit

    enddo

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key values of "//slKeys%list_all(),                             &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      lValues = pTarget%sl%get_logical()

    else

      allocate(lValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to lValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value(s) of: "//dquote(slKeys%list_all()), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

      lValues = FALSE

    endif

  end subroutine get_values_as_logical_given_list_of_keys_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_values_as_string_list_given_list_of_keys_sub(this, slKeys, slString, is_fatal )

    class (DICT_T)                                     :: this
    type (FSTRING_LIST_T)                               :: slKeys
    type ( FSTRING_LIST_T ), intent(out)                :: slString
    logical (c_bool), optional                         :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    integer (c_int)           :: iCount
    character (len=:), allocatable :: sText
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    iCount = 0

    do while ( iCount < slKeys%count )

      iCount = iCount + 1

      sText = slKeys%get( iCount)

      pTarget => this%get_entry( sText )

      if ( associated( pTarget ) ) exit

    enddo

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key values of "//slKeys%list_all(),                             &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      slString = pTarget%sl

    else

      call slString%append("<NA>")
      call warn(sMessage="Failed to find a dictionary entry associated with key value(s) of: "//dquote(slKeys%list_all()), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

    endif

  end subroutine get_values_as_string_list_given_list_of_keys_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_value_as_string_sub(this, sText, sKey, iIndex, is_fatal )

    class (DICT_T)                                  :: this
    character(len=:), allocatable, intent(out)      :: sText
    character (len=*), intent(in), optional         :: sKey
    integer (c_int), intent(in), optional           :: iIndex
    logical (c_bool), optional                      :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    if ( present( sKey ) )  this%current => this%get_entry(sKey)

    if ( present( iIndex ) )  this%current => this%get_entry( iIndex )

    if ( associated( this%current ) ) then

      sText = this%current%sl%get( 1, this%current%sl%count )

    else

      sText= ""

    endif

  end subroutine get_value_as_string_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_values_as_string_list_sub(this, sKey, slString, is_fatal)

    class (DICT_T)                                  :: this
    character (len=*), intent(in)                   :: sKey
    type (FSTRING_LIST_T), intent(out)               :: slString
    logical (c_bool), optional                      :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    pTarget => this%get_entry(sKey)

    if ( present(is_fatal) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = False
    endif

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key value of "//dquote(sKey),                                  &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      slString = pTarget%sl

    else

      call slString%append("<NA>")
      call warn(sMessage="Failed to find a dictionary entry associated with key value of "//dquote(sKey), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

    endif


  end subroutine get_values_as_string_list_sub

!--------------------------------------------------------------------------------------------------

  !> Search through keys for a match; return integer values.
  !!
  !! THis routine allows for multiple header values to be supplied
  !! in the search for the appropriate column.
  !! @param[in]  this  Object of DICT_T class.
  !! @param[in]  slKeys String list containing one or more possible key values to
  !!                    search for.
  !! @param[out] iValues Integer vector of values associated with one of the provided keys.

  subroutine get_values_as_int_given_list_of_keys_sub(this, slKeys, iValues, is_fatal)

    class (DICT_T)                                     :: this
    type (FSTRING_LIST_T)                               :: slKeys
    integer (c_int), allocatable, intent(out)          :: iValues(:)
    logical (c_bool), optional                         :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    integer (c_int)           :: iCount
    character (len=256)            :: sText
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    iCount = 0

    pTarget => null()

    do while ( iCount < slKeys%count )

      iCount = iCount + 1

      sText = slKeys%get( iCount)

      pTarget => this%get_entry( sText )

      if ( associated( pTarget ) ) exit

    enddo

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key values of "//slKeys%list_all(),                             &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      iValues = pTarget%sl%get_integer()

    else

      allocate(iValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to iValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value(s) of: "//dquote(slKeys%list_all()), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)

      iValues = iTINYVAL

    endif

  end subroutine get_values_as_int_given_list_of_keys_sub

!--------------------------------------------------------------------------------------------------

  !> Search through keys for a match; return float values.
  !!
  !! THis routine allows for multiple header values to be supplied
  !! in the search for the appropriate column.
  !! @param[in]  this  Object of DICT_T class.
  !! @param[in]  slKeys String list containing one or more possible key values to
  !!                    search for.
  !! @param[out] fValues Float vector of values associated with one of the provided keys.

  subroutine get_values_as_float_given_list_of_keys_sub(this, slKeys, fValues, is_fatal)

    class (DICT_T)                                    :: this
    type (FSTRING_LIST_T)                              :: slKeys
    real (c_float), allocatable, intent(out)          :: fValues(:)
    logical (c_bool), optional                        :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    integer (c_int)           :: iCount
    character (len=:), allocatable :: sText
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif

    iCount = 0
    pTarget => null()

    do while ( iCount < slKeys%count )

      iCount = iCount + 1

      sText = slKeys%get( iCount)

      pTarget => this%get_entry( sText )

      if ( associated( pTarget ) ) exit

    enddo

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key values of "//slKeys%list_all(),                             &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      fValues = pTarget%sl%get_float()

    else

      allocate(fValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to fValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value(s) of: "//dquote(slKeys%list_all()), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG, lEcho=FALSE)


      fValues = fTINYVAL

    endif


  end subroutine get_values_as_float_given_list_of_keys_sub

!--------------------------------------------------------------------------------------------------

  subroutine get_values_as_float_sub(this, sKey, fValues, is_fatal)

    class (DICT_T)                                    :: this
    character (len=*), intent(in)                     :: sKey
    real (c_float), allocatable, intent(out)          :: fValues(:)
    logical (c_bool), optional                        :: is_fatal

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: pTarget
    integer (c_int)           :: iStat
    logical (c_bool)          :: is_fatal_l
    logical (c_bool)          :: empty_entries

    if ( present( is_fatal ) ) then
      is_fatal_l = is_fatal
    else
      is_fatal_l = FALSE
    endif
    
    pTarget => this%get_entry(sKey)

    if ( associated( pTarget ) ) then

      if ( is_fatal_l ) then
        empty_entries = pTarget%sl%empty_entries_present()
        if( empty_entries )  call warn(sMessage="There are missing values associated" &
          //" with the key value of "//dquote(sKey),                                  &
          iLogLevel=LOG_ALL, lEcho=TRUE, lFatal=TRUE )
      endif

      fValues = pTarget%sl%get_float()

    else

      allocate(fValues(1), stat=iStat)
      call assert(iStat == 0, "Failed to allocate memory to iValues array", &
        __FILE__, __LINE__)

      call warn(sMessage="Failed to find a dictionary entry associated with key value of "//dquote(sKey), &
        sModule=__FILE__, iLine=__LINE__, iLogLevel=LOG_DEBUG , lEcho=FALSE)

      fValues = fTINYVAL

    endif

  end subroutine get_values_as_float_sub

!--------------------------------------------------------------------------------------------------

  subroutine print_all_dictionary_entries_sub(this, iLogLevel, sDescription, lEcho )

    class (DICT_T)                               :: this
    integer (c_int), intent(in), optional        :: iLogLevel
    character (len=*), intent(in), optional      :: sDescription
    logical (c_bool), intent(in), optional       :: lEcho

    ! [ LOCALS ]
    type (DICT_ENTRY_T), pointer   :: current
    character (len=512)            :: sTempBuf
    character (len=:), allocatable :: sDescription_
    integer (c_int)           :: iCount
    integer (c_int)           :: iIndex
    integer (c_int)           :: iLogLevel_l
    logical (c_bool)          :: lEcho_l

    if ( present( iLogLevel ) ) then
      iLogLevel_l = iLogLevel
    else
      iLogLevel_l = LOGS%iLogLevel
    end if

    if ( present( lEcho ) ) then
      lEcho_l = lEcho
    else
      lEcho_l = FALSE
    end if

    if ( present( sDescription ) ) then
      sDescription_ = trim(sDescription)
    else
      sDescription_ = "dictionary data structure"
    endif

    current => this%first
    iCount = 0

    call LOGS%write( "### Summary of all items stored in "//trim(sDescription_), &
      iLogLevel=iLogLevel_l, lEcho=lEcho_l )

    do while ( associated( current ) )

      iCount = iCount + 1
      sTempBuf = current%key

      call LOGS%write( asCharacter(iCount)//")  KEY: "//dquote(sTempBuf),    &
        iLogLevel=iLogLevel_l, lEcho=lEcho_l, iTab=2, iLinesBefore=1, iLinesAfter=1 )

      select case ( iLogLevel_l )

        case ( LOG_GENERAL )

          call current%sl%print( lu=LOGS%iUnitNum( LOG_GENERAL ) )

        case ( LOG_DEBUG )

          call current%sl%print( lu=LOGS%iUnitNum( LOG_DEBUG ) )

        case ( LOG_ALL )

          call current%sl%print( lu=LOGS%iUnitNum( LOG_GENERAL ) )
          call current%sl%print( lu=LOGS%iUnitNum( LOG_DEBUG ) )

        case default

      end select

      if ( lEcho_l )   call current%sl%print()

      current => current%next

    enddo

  end subroutine print_all_dictionary_entries_sub

end module dictionary
