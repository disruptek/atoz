
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Marketplace Catalog Service
## version: 2018-09-17
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Catalog API actions allow you to create, describe, list, and delete changes to your published entities. An entity is a product or an offer on AWS Marketplace.</p> <p>You can automate your entity update process by integrating the AWS Marketplace Catalog API with your AWS Marketplace product build or deployment pipelines. You can also create your own applications on top of the Catalog API to manage your products on AWS Marketplace.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/marketplace/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "catalog.marketplace.ap-northeast-1.amazonaws.com", "ap-southeast-1": "catalog.marketplace.ap-southeast-1.amazonaws.com", "us-west-2": "catalog.marketplace.us-west-2.amazonaws.com", "eu-west-2": "catalog.marketplace.eu-west-2.amazonaws.com", "ap-northeast-3": "catalog.marketplace.ap-northeast-3.amazonaws.com", "eu-central-1": "catalog.marketplace.eu-central-1.amazonaws.com", "us-east-2": "catalog.marketplace.us-east-2.amazonaws.com", "us-east-1": "catalog.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "catalog.marketplace.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "catalog.marketplace.ap-south-1.amazonaws.com", "eu-north-1": "catalog.marketplace.eu-north-1.amazonaws.com", "ap-northeast-2": "catalog.marketplace.ap-northeast-2.amazonaws.com", "us-west-1": "catalog.marketplace.us-west-1.amazonaws.com", "us-gov-east-1": "catalog.marketplace.us-gov-east-1.amazonaws.com", "eu-west-3": "catalog.marketplace.eu-west-3.amazonaws.com", "cn-north-1": "catalog.marketplace.cn-north-1.amazonaws.com.cn", "sa-east-1": "catalog.marketplace.sa-east-1.amazonaws.com", "eu-west-1": "catalog.marketplace.eu-west-1.amazonaws.com", "us-gov-west-1": "catalog.marketplace.us-gov-west-1.amazonaws.com", "ap-southeast-2": "catalog.marketplace.ap-southeast-2.amazonaws.com", "ca-central-1": "catalog.marketplace.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "catalog.marketplace.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "catalog.marketplace.ap-southeast-1.amazonaws.com",
      "us-west-2": "catalog.marketplace.us-west-2.amazonaws.com",
      "eu-west-2": "catalog.marketplace.eu-west-2.amazonaws.com",
      "ap-northeast-3": "catalog.marketplace.ap-northeast-3.amazonaws.com",
      "eu-central-1": "catalog.marketplace.eu-central-1.amazonaws.com",
      "us-east-2": "catalog.marketplace.us-east-2.amazonaws.com",
      "us-east-1": "catalog.marketplace.us-east-1.amazonaws.com",
      "cn-northwest-1": "catalog.marketplace.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "catalog.marketplace.ap-south-1.amazonaws.com",
      "eu-north-1": "catalog.marketplace.eu-north-1.amazonaws.com",
      "ap-northeast-2": "catalog.marketplace.ap-northeast-2.amazonaws.com",
      "us-west-1": "catalog.marketplace.us-west-1.amazonaws.com",
      "us-gov-east-1": "catalog.marketplace.us-gov-east-1.amazonaws.com",
      "eu-west-3": "catalog.marketplace.eu-west-3.amazonaws.com",
      "cn-north-1": "catalog.marketplace.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "catalog.marketplace.sa-east-1.amazonaws.com",
      "eu-west-1": "catalog.marketplace.eu-west-1.amazonaws.com",
      "us-gov-west-1": "catalog.marketplace.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "catalog.marketplace.ap-southeast-2.amazonaws.com",
      "ca-central-1": "catalog.marketplace.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "marketplace-catalog"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelChangeSet_601727 = ref object of OpenApiRestCall_601389
proc url_CancelChangeSet_601729(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelChangeSet_601728(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: JString (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `catalog` field"
  var valid_601841 = query.getOrDefault("catalog")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = nil)
  if valid_601841 != nil:
    section.add "catalog", valid_601841
  var valid_601842 = query.getOrDefault("changeSetId")
  valid_601842 = validateParameter(valid_601842, JString, required = true,
                                 default = nil)
  if valid_601842 != nil:
    section.add "changeSetId", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_CancelChangeSet_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_CancelChangeSet_601727; catalog: string;
          changeSetId: string): Recallable =
  ## cancelChangeSet
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  var query_601944 = newJObject()
  add(query_601944, "catalog", newJString(catalog))
  add(query_601944, "changeSetId", newJString(changeSetId))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var cancelChangeSet* = Call_CancelChangeSet_601727(name: "cancelChangeSet",
    meth: HttpMethod.HttpPatch, host: "catalog.marketplace.amazonaws.com",
    route: "/CancelChangeSet#catalog&changeSetId",
    validator: validate_CancelChangeSet_601728, base: "/", url: url_CancelChangeSet_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChangeSet_601984 = ref object of OpenApiRestCall_601389
proc url_DescribeChangeSet_601986(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeChangeSet_601985(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Provides information about a given change set.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: JString (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `catalog` field"
  var valid_601987 = query.getOrDefault("catalog")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = nil)
  if valid_601987 != nil:
    section.add "catalog", valid_601987
  var valid_601988 = query.getOrDefault("changeSetId")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = nil)
  if valid_601988 != nil:
    section.add "changeSetId", valid_601988
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601996: Call_DescribeChangeSet_601984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a given change set.
  ## 
  let valid = call_601996.validator(path, query, header, formData, body)
  let scheme = call_601996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601996.url(scheme.get, call_601996.host, call_601996.base,
                         call_601996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601996, url, valid)

proc call*(call_601997: Call_DescribeChangeSet_601984; catalog: string;
          changeSetId: string): Recallable =
  ## describeChangeSet
  ## Provides information about a given change set.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  var query_601998 = newJObject()
  add(query_601998, "catalog", newJString(catalog))
  add(query_601998, "changeSetId", newJString(changeSetId))
  result = call_601997.call(nil, query_601998, nil, nil, nil)

var describeChangeSet* = Call_DescribeChangeSet_601984(name: "describeChangeSet",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeChangeSet#catalog&changeSetId",
    validator: validate_DescribeChangeSet_601985, base: "/",
    url: url_DescribeChangeSet_601986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntity_601999 = ref object of OpenApiRestCall_601389
proc url_DescribeEntity_602001(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntity_602000(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the metadata and content of the entity.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   entityId: JString (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `entityId` field"
  var valid_602002 = query.getOrDefault("entityId")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "entityId", valid_602002
  var valid_602003 = query.getOrDefault("catalog")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = nil)
  if valid_602003 != nil:
    section.add "catalog", valid_602003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602004 = header.getOrDefault("X-Amz-Signature")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Signature", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_DescribeEntity_601999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata and content of the entity.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_DescribeEntity_601999; entityId: string; catalog: string): Recallable =
  ## describeEntity
  ## Returns the metadata and content of the entity.
  ##   entityId: string (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  var query_602013 = newJObject()
  add(query_602013, "entityId", newJString(entityId))
  add(query_602013, "catalog", newJString(catalog))
  result = call_602012.call(nil, query_602013, nil, nil, nil)

var describeEntity* = Call_DescribeEntity_601999(name: "describeEntity",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeEntity#catalog&entityId", validator: validate_DescribeEntity_602000,
    base: "/", url: url_DescribeEntity_602001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangeSets_602014 = ref object of OpenApiRestCall_601389
proc url_ListChangeSets_602016(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChangeSets_602015(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602017 = query.getOrDefault("MaxResults")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "MaxResults", valid_602017
  var valid_602018 = query.getOrDefault("NextToken")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "NextToken", valid_602018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602019 = header.getOrDefault("X-Amz-Signature")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Signature", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Content-Sha256", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Date")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Date", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Credential")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Credential", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Algorithm")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Algorithm", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-SignedHeaders", valid_602025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602027: Call_ListChangeSets_602014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  let valid = call_602027.validator(path, query, header, formData, body)
  let scheme = call_602027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602027.url(scheme.get, call_602027.host, call_602027.base,
                         call_602027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602027, url, valid)

proc call*(call_602028: Call_ListChangeSets_602014; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChangeSets
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602029 = newJObject()
  var body_602030 = newJObject()
  add(query_602029, "MaxResults", newJString(MaxResults))
  add(query_602029, "NextToken", newJString(NextToken))
  if body != nil:
    body_602030 = body
  result = call_602028.call(nil, query_602029, nil, nil, body_602030)

var listChangeSets* = Call_ListChangeSets_602014(name: "listChangeSets",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListChangeSets", validator: validate_ListChangeSets_602015, base: "/",
    url: url_ListChangeSets_602016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntities_602031 = ref object of OpenApiRestCall_601389
proc url_ListEntities_602033(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntities_602032(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides the list of entities of a given type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602034 = query.getOrDefault("MaxResults")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "MaxResults", valid_602034
  var valid_602035 = query.getOrDefault("NextToken")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "NextToken", valid_602035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Security-Token")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Security-Token", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602044: Call_ListEntities_602031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the list of entities of a given type.
  ## 
  let valid = call_602044.validator(path, query, header, formData, body)
  let scheme = call_602044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602044.url(scheme.get, call_602044.host, call_602044.base,
                         call_602044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602044, url, valid)

proc call*(call_602045: Call_ListEntities_602031; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntities
  ## Provides the list of entities of a given type.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602046 = newJObject()
  var body_602047 = newJObject()
  add(query_602046, "MaxResults", newJString(MaxResults))
  add(query_602046, "NextToken", newJString(NextToken))
  if body != nil:
    body_602047 = body
  result = call_602045.call(nil, query_602046, nil, nil, body_602047)

var listEntities* = Call_ListEntities_602031(name: "listEntities",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListEntities", validator: validate_ListEntities_602032, base: "/",
    url: url_ListEntities_602033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChangeSet_602048 = ref object of OpenApiRestCall_601389
proc url_StartChangeSet_602050(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChangeSet_602049(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation allows you to request changes in your entities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602051 = header.getOrDefault("X-Amz-Signature")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Signature", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Date")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Date", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Credential")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Credential", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Security-Token")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Security-Token", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-SignedHeaders", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_StartChangeSet_602048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation allows you to request changes in your entities.
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602059, url, valid)

proc call*(call_602060: Call_StartChangeSet_602048; body: JsonNode): Recallable =
  ## startChangeSet
  ## This operation allows you to request changes in your entities.
  ##   body: JObject (required)
  var body_602061 = newJObject()
  if body != nil:
    body_602061 = body
  result = call_602060.call(nil, nil, nil, nil, body_602061)

var startChangeSet* = Call_StartChangeSet_602048(name: "startChangeSet",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/StartChangeSet", validator: validate_StartChangeSet_602049, base: "/",
    url: url_StartChangeSet_602050, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
