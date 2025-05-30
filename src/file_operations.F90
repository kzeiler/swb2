module file_operations

  use iso_c_binding, only : c_int, c_float, c_double, c_bool
  use iso_fortran_env, only : IOSTAT_END
  use logfiles
  use exceptions
  use constants_and_conversions
  use fstring
  use fstring_list
  implicit none

  private

  public :: fully_qualified_filename

  integer (c_int), parameter         :: MAX_STR_LEN    = 65536

  type, public :: ASCII_FILE_T

    character (len=:), allocatable  :: sFilename
    character (len=:), allocatable  :: sDelimiters
    character (len=:), allocatable  :: sCommentChars
    type (FSTRING_LIST_T)           :: slColNames
    logical (c_bool)                :: remove_extra_delimiters = FALSE
    integer (c_int)                 :: iCurrentLinenum = 0
    integer (c_int)                 :: iNumberOfLines = 0
    integer (c_int)                 :: iNumberOfRecords = 0
    integer (c_int)                 :: iNumberOfHeaderLines = 1
    logical (c_bool)                :: lIsOpen = FALSE
    logical (c_bool)                :: lReadOnly = TRUE
    logical (c_bool)                :: lEOF = FALSE
    integer (c_int)                 :: iUnitNum
    integer (c_int)                 :: iStat
    character (len=MAX_STR_LEN)     :: sBuf
    character (len=:), allocatable  :: stMissingValue

  contains

    procedure, private :: open_file_read_access_sub
    procedure, private :: open_file_write_access_sub
    generic :: open => open_file_read_access_sub, &
                       open_file_write_access_sub

    procedure, private :: close_file_sub
    generic :: close => close_file_sub

    procedure, private :: is_file_open_fn
    generic :: isOpen => is_file_open_fn

    procedure, private :: have_we_reached_the_EOF_fn
    generic :: isEOF => have_we_reached_the_EOF_fn

    procedure, private :: does_file_exist_fn
    generic :: exists => does_file_exist_fn

    procedure, private :: is_current_line_a_comment_fn
    generic :: isComment => is_current_line_a_comment_fn

    procedure, private :: count_number_of_lines_sub
    generic :: countLines => count_number_of_lines_sub

    procedure, private :: return_num_lines_fn
    generic :: numLines => return_num_lines_fn

    procedure, private :: return_num_records_fn
    generic :: numRecords => return_num_records_fn

    procedure, private :: return_current_linenum_fn
    generic :: currentLineNum => return_current_linenum_fn

    procedure, private :: return_fortran_unit_number_fn
    generic :: unit => return_fortran_unit_number_fn

    procedure, private :: read_header_fn
    generic, public    :: readHeader => read_header_fn

    procedure, private :: read_line_of_data_fn
    generic, public    :: readLine => read_line_of_data_fn

    procedure, private :: write_line_of_data_sub
    generic, public    :: writeLine => write_line_of_data_sub

  end type ASCII_FILE_T

contains

  function return_fortran_unit_number_fn(this)   result(iUnitNum)

    class (ASCII_FILE_T)   :: this
    integer (c_int)   :: iUnitNum

    iUnitNum = this%iUnitNum

  end function return_fortran_unit_number_fn

!--------------------------------------------------------------------------------------------------

  function return_num_lines_fn(this)    result(iNumLines)

    class (ASCII_FILE_T)   :: this
    integer (c_int) :: iNumLines

    iNumLines = this%iNumberOfLines

  end function return_num_lines_fn

!--------------------------------------------------------------------------------------------------

  function return_num_records_fn(this)                 result(iNumRecords)

    class (ASCII_FILE_T)   :: this
    integer (c_int) :: iNumRecords

    iNumRecords = this%iNumberOfRecords

  end function return_num_records_fn

!--------------------------------------------------------------------------------------------------

  function return_current_linenum_fn(this)          result(iCurrentLinenum)

    class (ASCII_FILE_T)   :: this
    integer (c_int) :: iCurrentLinenum

    iCurrentLinenum = this%iCurrentLinenum

  end function return_current_linenum_fn

!--------------------------------------------------------------------------------------------------

  function have_we_reached_the_EOF_fn(this)           result(lIsEOF)

    class (ASCII_FILE_T)     :: this
    logical (c_bool)   :: lIsEOF

    lIsEOF = this%lEOF

  end function have_we_reached_the_EOF_fn

!--------------------------------------------------------------------------------------------------

  function is_current_line_a_comment_fn(this)         result(lIsComment)

    class (ASCII_FILE_T)     :: this
    logical (c_bool)   :: lIsComment

    ! [ LOCALS ]
    integer (c_int) :: iIndex
    integer (c_int) :: iLen
    character (len=1)   :: sBufTemp

    iLen = len_trim( this%sBuf )

    sBufTemp = adjustl(this%sBuf)

    iIndex = verify( sBufTemp , this%sCommentChars )

    lIsComment = FALSE

    if ( iIndex == 0 .or. len_trim(this%sBuf) == 0 ) lIsComment = TRUE

  end function is_current_line_a_comment_fn

!--------------------------------------------------------------------------------------------------

  subroutine open_file_read_access_sub(this, sFilename, sCommentChars, sDelimiters, lHasHeader )

    class (ASCII_FILE_T), intent(inout)         :: this
    character (len=*), intent(in)               :: sFilename
    character (len=*), intent(in)               :: sCommentChars
    character (len=*), intent(in)               :: sDelimiters
    logical (c_bool), intent(in), optional :: lHasHeader

    ! [ LOCALS ]
    character (len=len(sFilename) ) :: sFilename_l

    ! 'fix_pathname' simply replaces forward slashes and backslashes with whatever the native OS
    ! path delimiter character should be
    sFilename_l = fix_pathname( sFilename )
    
    this%sCommentChars = sCommentChars
    this%sDelimiters = sDelimiters

    if (present( lHasHeader ) ) then
      if (.not. lHasHeader ) this%iNumberOfHeaderLines = 0
    endif

    if ( this%isOpen() ) then

      call die( "PROGRAMMING ERROR--file already open: "//dquote( fully_qualified_filename( sFilename_l ) )//"." )

    else

      open(newunit=this%iUnitNum, file=fully_qualified_filename( sFilename_l ), iostat=this%iStat, action='READ')
      call assert(this%iStat == 0, "Failed to open file "//dquote( fully_qualified_filename( sFilename_l ) )//"."  &
        //" Exit code: "//asCharacter( this%iStat )//".", __FILE__, __LINE__)

      this%lIsOpen = TRUE
      this%lEOF = FALSE

      call this%countLines()

      call LOGS%write( sMessage="Opened file "//dquote( fully_qualified_filename( sFilename_l ) ), iTab=22, &
                       iLinesBefore=1, iLogLevel=LOG_ALL )
      call LOGS%write( "Comment characters: "//dquote(sCommentChars), iTab=42 )
      call LOGS%write( "Number of lines in file: "//asCharacter( this%numLines() ), iTab=37 )
      call LOGS%write( "Number of lines excluding blanks, headers and comments: " &
           //asCharacter( this%numRecords() ), iTab=6 )

    endif

  end subroutine open_file_read_access_sub

!--------------------------------------------------------------------------------------------------

  subroutine open_file_write_access_sub(this, sFilename, lQuiet )

    class (ASCII_FILE_T), intent(inout)           :: this
    character (len=*), intent(in)                 :: sFilename
    logical (c_bool), intent(in), optional   :: lQuiet

    ! [ LOCALS ]
    logical :: lQuiet_l
    character (len=len(sFilename) ) :: sFilename_l

    sFilename_l = fix_pathname( sFilename )

    if ( present( lQuiet ) ) then
      lQuiet_l = lQuiet
    else
      lQuiet_l = FALSE
    endif

    if (.not. this%isOpen() ) then

      open(newunit=this%iUnitNum, file=sFilename_l, iostat=this%iStat, action='WRITE')
      call assert(this%iStat == 0, "Failed to open file "//dquote(sFilename_l)//".", __FILE__, __LINE__)

      this%lIsOpen = TRUE
      this%lEOF = FALSE
      this%lReadOnly = FALSE
      this%sFilename = trim(sFilename_l)

      if ( .not. lQuiet_l ) &
        call LOGS%write( "Opened file with write access: "//dquote(sFilename_l))

    else
      call LOGS%write( "Failed to open file "//dquote(sFilename_l)//" with WRITE access" )
    endif

  end subroutine open_file_write_access_sub

!--------------------------------------------------------------------------------------------------

  subroutine close_file_sub(this)

    class (ASCII_FILE_T) :: this

    integer (c_int)      :: iStat

    close(unit=this%iUnitNum, iostat=this%iStat)
    
    this%lIsOpen = FALSE

  end subroutine close_file_sub

!--------------------------------------------------------------------------------------------------

  function does_file_exist_fn(this, sFilename) result(lExists)

    class (ASCII_FILE_T)              :: this
    character (len=*), intent(in)    :: sFilename
    logical(c_bool)             :: lExists

    inquire(file=fully_qualified_filename( sFilename ), exist=lExists)

  end function does_file_exist_fn

!--------------------------------------------------------------------------------------------------

  function is_file_open_fn(this) result(lIsOpen)

    class (ASCII_FILE_T) :: this
    logical(c_bool) :: lIsOpen

    lIsOpen = this%lIsOpen

  end function is_file_open_fn

!--------------------------------------------------------------------------------------------------

  subroutine count_number_of_lines_sub(this)

    class (ASCII_FILE_T), intent(inout) :: this

    ! [ LOCALS ]
    integer (c_int) :: iStat
    integer (c_int) :: iNumLines
    integer (c_int) :: iNumRecords
    integer (c_int) :: iIndex

    iNumLines = 0
    iNumRecords = 0
    iStat = 0

    if ( this%isOpen() ) then

      rewind( unit = this%iUnitNum )

      do

        read (unit = this%iUnitNum, fmt="(a)", iostat = iStat)  this%sBuf

        if (iStat == IOSTAT_END) exit

        iNumLines = iNumLines + 1

        if ( .not. this%isComment() )   iNumRecords = iNumRecords + 1

      enddo

      rewind( unit = this%iUnitNum )

      this%iNumberOfLines= iNumLines
      this%iNumberOfRecords = iNumRecords - this%iNumberOfHeaderLines

    endif

  end subroutine count_number_of_lines_sub

!--------------------------------------------------------------------------------------------------

  function read_header_fn(this) result (stList)

    class (ASCII_FILE_T), intent(inout) :: this
    type (FSTRING_LIST_T) :: stList

    ! [ LOCALS ]
    character (len=MAX_STR_LEN)           :: sString
    character (len=MAX_STR_LEN)           :: sSubString
    character (len=MAX_STR_LEN)           :: sSubStringClean
    integer (c_int)                       :: iStat

    this%sBuf = this%readline()
    call stList%clear()

    do while ( len_trim( this%sBuf ) > 0)

      call chomp( str=this%sBuf, substr=sSubString, delimiter_chr=this%sDelimiters,   &
                  remove_extra_delimiters=this%remove_extra_delimiters )

      call replace(sSubString, " ", "_")
      call replace(sSubString, ".", "_")
      sSubStringClean = trim( clean( sSubString, DOUBLE_QUOTE ) )
      call stList%append( trim( adjustl( sSubStringClean ) ) )

    enddo

  end function read_header_fn

!--------------------------------------------------------------------------------------------------

  subroutine write_line_of_data_sub( this, sText )

    class (ASCII_FILE_T), intent(inout)         :: this
    character (len=*), intent(in)               :: sText

    ! [ LOCALS ]
    integer (c_int) :: iStat

    call assert( .not. this%lReadOnly, "INTERNAL ERROR -- File "  &
      //dquote( fully_qualified_filename( this%sFilename ) )      &
      //" was opened as READONLY.", __FILE__, __LINE__ )

    if (this%isOpen() ) then

      write ( unit = this%iUnitNum, fmt = "(a)", iostat = iStat ) trim(sText)

    endif

  end subroutine write_line_of_data_sub

!--------------------------------------------------------------------------------------------------

  function read_line_of_data_fn(this) result(sText)

    class (ASCII_FILE_T), intent(inout) :: this
    character (len=:), allocatable     :: sText

    ! [ LOCALS ]
    integer (c_int) :: iStat
    logical (c_bool)                 :: lIsComment

    lIsComment = TRUE

    do while ( lIsComment .and. this%isOpen() )

      if (this%isOpen() ) then

        read (unit = this%iUnitNum, fmt = "(a)", iostat = iStat) this%sBuf

        if (iStat == IOSTAT_END) then
          this%lEOF = TRUE
          sText = ""
          call this%close()
        else
          sText = trim(this%sBuf)
          this%iCurrentLinenum = this%iCurrentLinenum + 1
        endif

        lIsComment = this%isComment()

      endif

    enddo

  end function read_line_of_data_fn

!--------------------------------------------------------------------------------------------------

  function fully_qualified_filename( filename, pathname )

    character(len=*), intent(in)            :: filename
    character(len=*), intent(in), optional  :: pathname
    character(len=:), allocatable           :: fully_qualified_filename

    if (.not. present(pathname) ) then

      fully_qualified_filename = fix_pathname(filename)

    else

      fully_qualified_filename = trim( pathname )//fix_pathname(filename)

    endif

  end function fully_qualified_filename


end module file_operations
