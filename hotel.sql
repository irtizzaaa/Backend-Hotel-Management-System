use master
go

create database hotel
go

use hotel
go

drop database hotel

create table Users 
( UserId int primary key, 
  Name varchar(50) NOT NULL, 
  Phone char(11) NOT NULL unique,
  Gender varchar(6) check(Gender in ('Male','Female', 'Other')) NOT NULL,
  Age int,
  UserType varchar(10) check(UserType in ('Admin','Employee', 'User')) NOT NULL,
  Points float default 0.0
)
go

create table [Login] 
( Email varchar(50) primary key,
  [Password] varchar(100) NOT NULL, --(length([Password]) > 8 AND [Password] like '%[A-Z]%' AND [Password] like '%[0-9]%')
)
go

create table Hotels 
( HotelId int primary key, 
  OwnerId int foreign key references Users(UserId) on delete NO ACTION on update cascade NOT NULL,
  HotelName varchar(50) NOT NULL,
  HotelAddress varchar(50) NOT NULL,
  NoOfRooms int NOT NULL,
  HotelRating float 
)
go

create table Rooms 
( RoomNo int primary key NOT NULL,
  HotelId int foreign key references Hotels(HotelId) on delete NO ACTION on update cascade NOT NULL,
  NoOfBeds int NOT NULL,
  RoomPrice float, --per day
  RoomStatus varchar(20) NOT NULL
)
go

create table Rating 
( HotelId int foreign key references Hotels(HotelId) on delete NO ACTION on update NO ACTION,
  UserId int foreign key references Users(UserId) on delete NO ACTION on update NO ACTION,
  UserRating int check(UserRating >= 0 and UserRating <=5),
  UserComment varchar(500),
  primary key(HotelId, UserId)
)
go

create table Packages 
( PackageId int primary key,
  HotelId int foreign key references Hotels(HotelId) on delete NO ACTION on update cascade, 
  PackageDescription varchar(500) NOT NULL,
  PackageStart date NOT NULL,
  PackageEnd date NOT NULL,
  Price float NOT NULL,
)
go

create table Rewards 
( Points float default 0.0 NOT NULL,
  Reward varchar(100) default 0.0, --clarify
  [Description] varchar(200) NOT NULL
)
go

create table Booking
( BookingId int primary key,
  UserId int foreign key references Users(UserId) on delete NO ACTION on update Cascade NOT NULL,
  HotelId int foreign key references Hotels(HotelId) on delete NO ACTION on update NO ACTION NOT NULL,
  RoomNo int foreign key references Rooms(RoomNo) on delete NO ACTION on update NO ACTION NOT NULL,
  PackageId int foreign key references Packages(PackageId) on delete NO ACTION on update NO ACTION,
  BookingDate timestamp NOT NULL,
  [Status] varchar(11) check([Status] in ('Arrived','Not Arrived', 'Pending')) NOT NULL,
  CheckIn datetime NOT NULL,
  CheckOut datetime NOT NULL
)
go

create table CancelBooking
( BookingId int foreign key references Booking(BookingId) on delete NO ACTION on update cascade,
  UserId int foreign key references Users(UserId) on delete NO ACTION on update NO ACTION,
  CancelationTime timestamp NOT NULL,
  [Description] varchar(200) NOT NULL,
  Primary key(BookingId, UserId)
)
go

create table Payment
( BookingId int foreign key references Booking(BookingId) on delete NO ACTION on update Cascade,
  UserId int foreign key references Users(UserId) on delete NO ACTION on update NO ACTION,
  PaymentType varchar(13) check (PaymentType in ('Cash','Credit & Cash')) NOT NULL,
  TotalAmount float NOT NULL,
  BookingTime timestamp NOT NULL,
  Primary key(BookingId, UserId)
)
go

create table Blacklist 
( UserId int foreign key references Users(UserId) on delete NO ACTION on update NO ACTION,
  HotelId int foreign key references Hotels(HotelId) on delete NO ACTION on update NO ACTION,
  [Description] varchar(200) NOT NULL,
  primary key(UserId, HotelId)
)
go

create table Complaints
( UserId int foreign key references Users(UserId) on delete NO ACTION on update cascade,
  [Description] varchar(200) NOT NULL,
  [status] varchar(5) check ([status] in ('Open','Closed')) NOT NULL,
  primary key(UserId)
)
go


--Procedures
---------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure AddUser
@UserId int,
@Name varchar(50),
@Phone char(11),
@Gender varchar(6),
@Age int,
@UserType varchar(10),
@Points float
As
Begin
	insert into Users values(@UserId, @Name, @Phone, @Gender, @Age, @UserType, @Points)
End
go

Execute AddUser @UserId= 123, @Name='Ahsan Khan', @Phone='03085214677', @Gender='Male', @Age= 25, @UserType='User', @Points=0
Select *
From Users

----------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure BlackListUser
@UserId int,
@HotelId int,
@Description varchar(200)
As
Begin
     If exists( Select UserId
	            From Booking
				Where UserId = @UserId AND HotelId = @HotelId AND [Status] = 'Not Arrived'
				Group by UserId
				Having count([status])>3 )
	Begin
	insert into BlackList values(@UserId, @HotelId, @Description)
	End
End
go

Execute BlackListUser @UserId = 123, @HotelId = 112, @Description = 'Not arrived to booking more than 3 times'
Select *
From BlackList

drop procedure BlackListUser

----------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure UserPayment
@BookingId int,
@UserId int,
@PaymentType varchar(13),
@TotalAmount float,
@BookingTime varbinary(8)
As
Begin
     
	 If exists ( Select BookingId 
	             From Booking
				 Where BookingId = @BookingId AND UserId = @UserID )
	 
	 Begin

	 set @TotalAmount = ( Select (RoomPrice * datediff(day, checkin, checkout)) - Price
	                      From (Rooms as R join Booking as B on R.RoomNo = B.RoomNo) join Packages as P on P.PackageId = B.PackageId )

	 Insert into Payment values(@BookingId, @UserId, @PaymentType, @TotalAmount, @BookingTime)
	 End

	 Else
	 Begin
	 Print 'Booking does not exist please type correct BookingId & UserId'
	 End
End
go

Execute UserPayment @BookingId = 123, @UserId = 111, @PaymentType = 'Cash', @TotalAmount = 0, @BookingTime = gettimestamp
Select *
From Payment

----------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure SignUp
@Email varchar(50),
@Password varchar(100)
As
Begin

	If exists ( Select Email
	            From [Login]
	            Where Email = @Email )
    Begin
	Print 'Email already exists!'
    End

    Else

	Begin
	Insert into [Login] values(@Email, @Password)
	Print 'Account created'
	End

End
go

Execute SignUp @Email = 'ahhs@gmail.com', @Password = 'QWERTY123$'
Select *
From [Login]

drop procedure SignUp

----------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure SignIn
@Email varchar(50),
@Password varchar(100)
As
Begin
	If exists ( Select *
	            From [Login]
	            Where Email = @Email AND [Password] = @Password )

	Begin
	Print 'SignIn successful'
	End

	Else

	Begin
	Print 'SignIn unsuccessful'
	End

End
go

Execute SignIn @Email = 'ahhs@gmail.com', @Password = 'QWERTY123$'

----------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure AddComplaint
@UserId int,
@Description varchar(200)
As
Begin
	insert into complaints values(@UserId, @Description,'Open')
End
go

Execute AddComplaint @UserId = 123, @Description = 'Room was not clean'
Select *
From Complaints

----------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure UpdateComplaint
@UserId int
As
Begin
	update complaints set [status] = 'Closed' Where UserId = @UserId
End
go

Execute UpdateComplaint @UserId = 123
Select *
From Complaints

----------------------------------------------------------------------------------------------------------------------------------------------------------------