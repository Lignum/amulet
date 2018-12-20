{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}

-- | This monster of a module declares any built-in variables, or
-- variables the compiler has intrinsic knowledge of.
--
-- Any "internal" variable has a negative index which, like other
-- indexes, should be unique.
module Core.Builtin where

import Data.Text ()

import Core.Core
import Core.Var

vBool, vInt, vString, vFloat, vUnit, vLazy, vArrow, vProduct, vList, vShow :: CoVar
vBool    = CoVar (-1) "bool" TypeConVar
vInt     = CoVar (-2) "int" TypeConVar
vString  = CoVar (-3) "string" TypeConVar
vFloat   = CoVar (-4) "float" TypeConVar
vUnit    = CoVar (-5) "unit" TypeConVar
vLazy    = CoVar (-34) "lazy" TypeConVar
vArrow   = CoVar (-38) "->" TypeConVar
vProduct = CoVar (-39) "*" TypeConVar
vList    = CoVar (-40) "list" TypeConVar
vShow    = CoVar (-43) "show" TypeConVar

tyBool, tyInt, tyString, tyFloat, tyUnit, tyLazy, tyList, tyShow
  :: IsVar a => Type a
tyBool   = ConTy $ fromVar vBool
tyInt    = ConTy $ fromVar vInt
tyString = ConTy $ fromVar vString
tyUnit   = ConTy $ fromVar vUnit
tyFloat  = ConTy $ fromVar vFloat
tyLazy   = ConTy $ fromVar vLazy
tyList   = ConTy $ fromVar vList
tyShow   = ConTy $ fromVar vShow

builtinTyList :: IsVar a => [a]
builtinTyList = [ fromVar vBool
                , fromVar vInt
                , fromVar vString
                , fromVar vUnit
                , fromVar vFloat
                , fromVar vLazy
                , fromVar vArrow
                , fromVar vProduct
                , fromVar vList
                , fromVar vShow
                ]

vOpAdd, vOpSub, vOpMul, vOpDiv, vOpExp :: CoVar
vOpAdd = CoVar (-6) "+" ValueVar
vOpSub = CoVar (-7) "-" ValueVar
vOpMul = CoVar (-8) "*" ValueVar
vOpDiv = CoVar (-9) "/" ValueVar
vOpExp = CoVar (-10) "**" ValueVar


vOpLt, vOpGt, vOpLe, vOpGe :: CoVar
vOpLt = CoVar (-11) "<" ValueVar
vOpGt = CoVar (-12) ">" ValueVar
vOpLe = CoVar (-13) "<=" ValueVar
vOpGe = CoVar (-14) ">=" ValueVar

vOpAddF, vOpSubF, vOpMulF, vOpDivF, vOpExpF :: CoVar
vOpAddF = CoVar (-15) "+." ValueVar
vOpSubF = CoVar (-16) "-." ValueVar
vOpMulF = CoVar (-17) "*." ValueVar
vOpDivF = CoVar (-18) "/." ValueVar
vOpExpF = CoVar (-19) "**." ValueVar

vOpLtF, vOpGtF, vOpLeF, vOpGeF :: CoVar
vOpLtF = CoVar (-20) "<." ValueVar
vOpGtF = CoVar (-21) ">." ValueVar
vOpLeF = CoVar (-22) "<=." ValueVar
vOpGeF = CoVar (-23) ">=." ValueVar

vOpConcat :: CoVar
vOpConcat = CoVar (-24) "^" ValueVar

vOpEq, vOpNe :: CoVar
vOpEq = CoVar (-25) "==" ValueVar
vOpNe = CoVar (-26) "<>" ValueVar

vError :: CoVar
vError = CoVar (-29) "error" ValueVar

vLAZY, vForce :: CoVar
vLAZY = CoVar (-35) "lazy" ValueVar
vForce = CoVar (-36) "force" ValueVar

tyvarA, tyvarB, argvarX :: CoVar
tyvarA = CoVar (-30) "a" TypeVar
tyvarB = CoVar (-31) "b" TypeVar
argvarX = CoVar (-46) "x" ValueVar

vOpApp, vOpShow :: CoVar
vOpApp = CoVar (-32) "@@" ValueVar
vOpShow = CoVar (-44) "show" ValueVar

vCONS, vNIL, vSHOW :: CoVar
vCONS = CoVar (-41) "Cons" DataConVar
vNIL = CoVar (-42) "Nil" DataConVar
vSHOW = CoVar (-45) "Show" ValueVar

builtinVarList :: forall a b. (IsVar a, IsVar b) => [(a, Type b)]
builtinVarList = vars where
  op x t = (fromVar x, t)

  tupTy = ValuesTy
  arrTy = ForallTy Irrelevant
  prodTy a b = RowsTy NilTy [("_1", a), ("_2", b)]

  intOp, floatOp, stringOp, intCmp, floatCmp :: Type b
  intOp = tupTy [tyInt, tyInt] `arrTy` tyInt
  floatOp = tupTy [tyFloat, tyFloat] `arrTy` tyFloat
  stringOp = tupTy [tyString, tyString] `arrTy` tyString
  intCmp = tupTy [tyInt, tyInt] `arrTy` tyBool
  floatCmp = tupTy [tyFloat, tyFloat] `arrTy` tyBool

  cmp = ForallTy (Relevant name) StarTy $ tupTy [VarTy name, VarTy name] `arrTy` tyBool

  name, name' :: b
  name = fromVar tyvarA
  name' = fromVar tyvarB

  vars :: [(a, Type b)]
  vars = [ op vOpAdd intOp, op vOpSub intOp
         , op vOpMul intOp, op vOpDiv (tupTy [tyInt, tyInt] `arrTy` tyFloat), op vOpExp intOp
         , op vOpLt intCmp, op vOpGt intCmp, op vOpLe intCmp, op vOpGe intCmp

         , op vOpAddF floatOp, op vOpSubF floatOp, op vOpMulF floatOp, op vOpDivF floatOp, op vOpExpF floatOp
         , op vOpLtF floatCmp, op vOpGtF floatCmp, op vOpLeF floatCmp, op vOpGeF floatCmp

         , op vOpConcat stringOp

         , op vOpEq cmp, op vOpNe cmp
         , op vOpApp
            (ForallTy (Relevant name) StarTy $
               ForallTy (Relevant name') StarTy $
                 ValuesTy [VarTy name `arrTy` VarTy name', VarTy name] `arrTy` VarTy name')

         , op vError (ForallTy (Relevant name) StarTy $ tyString `arrTy` VarTy name)

         , op vLAZY (ForallTy (Relevant name) StarTy $
            (tyUnit `arrTy` VarTy name) `arrTy` AppTy tyLazy (VarTy name))
         , op vForce (ForallTy (Relevant name) StarTy $ AppTy tyLazy (VarTy name) `arrTy` VarTy name)

         , op vCONS (ForallTy (Relevant name) StarTy $
                      VarTy name `prodTy` AppTy tyList (VarTy name) `arrTy` AppTy tyList (VarTy name))
         , op vNIL (ForallTy (Relevant name) StarTy $ AppTy tyList (VarTy name))

         , op vOpShow $
             ForallTy (Relevant name) StarTy $
               AppTy tyShow (VarTy name) `arrTy` (VarTy name `arrTy` tyString)

         , op vSHOW $
             ForallTy (Relevant name) StarTy $
               (VarTy name `arrTy` tyString) `arrTy` AppTy tyShow (VarTy name)
         ]

isError :: IsVar a => a -> Bool
isError = (==vError) . toVar

fakeShow, fakeSHOW :: IsVar a => Term a
fakeShow =
  Lam (TypeArgument (fromVar tyvarA) StarTy) $
    Lam (TermArgument (fromVar argvarX) (AppTy tyShow (VarTy (fromVar tyvarA)))) $
      (Cast (Ref (fromVar argvarX) (AppTy tyShow (VarTy (fromVar tyvarA))))
        (SameRepr (AppTy tyShow (VarTy (fromVar tyvarA)))
          (ArrTy (VarTy (fromVar tyvarA)) tyString)))
fakeSHOW =
  Lam (TypeArgument (fromVar tyvarA) StarTy) $
    Lam (TermArgument (fromVar argvarX) (ArrTy (VarTy (fromVar tyvarA)) tyString)) $
      (Cast (Ref (fromVar argvarX) (ArrTy (VarTy (fromVar tyvarA)) tyString))
        (Symmetry
          (SameRepr (AppTy tyShow (VarTy (fromVar tyvarA)))
            (ArrTy (VarTy (fromVar tyvarA)) tyString))))
