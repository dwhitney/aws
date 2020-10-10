module AWS.DynamoDB.Optics where

import Prelude

import AWS.DynamoDB.Types (AttributeValue(..), InsertItem, ModifyItem, StreamEvent(..), RemoveItem)
import Data.Either (Either(..))
import Data.Lens (Prism, Prism', prism)
import Foreign.Object (Object)

_B :: Prism' AttributeValue String 
_B = prism B case _ of 
  B str -> Right str
  notB -> Left notB

_BS :: Prism' AttributeValue (Array String)
_BS = prism BS case _ of 
  BS strs -> Right strs
  notBS -> Left notBS

_BOOL :: Prism' AttributeValue Boolean
_BOOL = prism BOOL case _ of 
  BOOL bool -> Right bool 
  notBool -> Left notBool

_L :: Prism' AttributeValue (Array AttributeValue)
_L = prism L case _ of 
  L ls -> Right ls 
  notLs -> Left notLs

_M :: Prism' AttributeValue (Object AttributeValue)
_M = prism M case _ of 
  M m -> Right m 
  notM -> Left notM 

_N :: Prism' AttributeValue String
_N = prism N case _ of 
  N n -> Right n 
  notN -> Left notN 

_NS :: Prism' AttributeValue (Array String)
_NS = prism NS case _ of 
  NS ns -> Right ns
  notNS -> Left notNS

_NULL :: Prism (AttributeValue) (AttributeValue) Unit Unit
_NULL = prism (const NULL) $ case _ of 
  NULL    -> Right unit 
  notNULL -> Left notNULL 

_S :: Prism' AttributeValue String
_S = prism S case _ of 
  S s -> Right s 
  notS -> Left notS 

_SS :: Prism' AttributeValue (Array String)
_SS = prism SS case _ of 
  NS ss -> Right ss
  notSS -> Left notSS

_Insert :: Prism' StreamEvent InsertItem
_Insert = prism Insert case _ of
  Insert rec  -> Right rec
  notIns      -> Left notIns

_Modify :: Prism' StreamEvent ModifyItem
_Modify = prism Modify case _ of
  Modify rec  -> Right rec
  notRec      -> Left notRec

_Remove :: Prism' StreamEvent RemoveItem
_Remove = prism Remove case _ of
  Remove rec  -> Right rec
  notRec      -> Left notRec