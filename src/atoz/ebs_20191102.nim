
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic Block Store
## version: 2019-11-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>You can use the Amazon Elastic Block Store (EBS) direct APIs to directly read the data on your EBS snapshots, and identify the difference between two snapshots. You can view the details of blocks in an EBS snapshot, compare the block difference between two snapshots, and directly access the data in a snapshot. If you’re an independent software vendor (ISV) who offers backup services for EBS, the EBS direct APIs make it easier and more cost-effective to track incremental changes on your EBS volumes via EBS snapshots. This can be done without having to create new volumes from EBS snapshots.</p> <p>This API reference provides detailed information about the actions, data types, parameters, and errors of the EBS direct APIs. For more information about the elements that make up the EBS direct APIs, and examples of how to use them effectively, see <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshot.html">Accessing the Contents of an EBS Snapshot</a> in the <i>Amazon Elastic Compute Cloud User Guide</i>. For more information about the supported AWS Regions, endpoints, and service quotas for the EBS direct APIs, see <a href="https://docs.aws.amazon.com/general/latest/gr/ebs-service.html">Amazon Elastic Block Store Endpoints and Quotas</a> in the <i>AWS General Reference</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ebs/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
                               "us-west-2": "ebs.us-west-2.amazonaws.com",
                               "eu-west-2": "ebs.eu-west-2.amazonaws.com", "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com", "eu-central-1": "ebs.eu-central-1.amazonaws.com",
                               "us-east-2": "ebs.us-east-2.amazonaws.com",
                               "us-east-1": "ebs.us-east-1.amazonaws.com", "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "ebs.ap-south-1.amazonaws.com",
                               "eu-north-1": "ebs.eu-north-1.amazonaws.com", "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
                               "us-west-1": "ebs.us-west-1.amazonaws.com", "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "ebs.eu-west-3.amazonaws.com",
                               "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "ebs.sa-east-1.amazonaws.com",
                               "eu-west-1": "ebs.eu-west-1.amazonaws.com", "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
      "us-west-2": "ebs.us-west-2.amazonaws.com",
      "eu-west-2": "ebs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ebs.eu-central-1.amazonaws.com",
      "us-east-2": "ebs.us-east-2.amazonaws.com",
      "us-east-1": "ebs.us-east-1.amazonaws.com",
      "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ebs.ap-south-1.amazonaws.com",
      "eu-north-1": "ebs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
      "us-west-1": "ebs.us-west-1.amazonaws.com",
      "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ebs.eu-west-3.amazonaws.com",
      "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ebs.sa-east-1.amazonaws.com",
      "eu-west-1": "ebs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ebs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetSnapshotBlock_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetSnapshotBlock_402656290(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  assert "blockIndex" in path, "`blockIndex` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
                 (kind: VariableSegment, value: "snapshotId"),
                 (kind: ConstantSegment, value: "/blocks/"),
                 (kind: VariableSegment, value: "blockIndex"),
                 (kind: ConstantSegment, value: "#blockToken")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSnapshotBlock_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
                                 ##             : The ID of the snapshot containing the block from which to get data.
  ##   
                                                                                                                     ## blockIndex: JInt (required)
                                                                                                                     ##             
                                                                                                                     ## : 
                                                                                                                     ## <p>The 
                                                                                                                     ## block 
                                                                                                                     ## index 
                                                                                                                     ## of 
                                                                                                                     ## the 
                                                                                                                     ## block 
                                                                                                                     ## from 
                                                                                                                     ## which 
                                                                                                                     ## to 
                                                                                                                     ## get 
                                                                                                                     ## data.</p> 
                                                                                                                     ## <p>Obtain 
                                                                                                                     ## the 
                                                                                                                     ## <code>BlockIndex</code> 
                                                                                                                     ## by 
                                                                                                                     ## running 
                                                                                                                     ## the 
                                                                                                                     ## <code>ListChangedBlocks</code> 
                                                                                                                     ## or 
                                                                                                                     ## <code>ListSnapshotBlocks</code> 
                                                                                                                     ## operations.</p>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `snapshotId` field"
  var valid_402656380 = path.getOrDefault("snapshotId")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "snapshotId", valid_402656380
  var valid_402656381 = path.getOrDefault("blockIndex")
  valid_402656381 = validateParameter(valid_402656381, JInt, required = true,
                                      default = nil)
  if valid_402656381 != nil:
    section.add "blockIndex", valid_402656381
  result.add "path", section
  ## parameters in `query` object:
  ##   blockToken: JString (required)
                                  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>BlockToken</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `blockToken` field"
  var valid_402656382 = query.getOrDefault("blockToken")
  valid_402656382 = validateParameter(valid_402656382, JString, required = true,
                                      default = nil)
  if valid_402656382 != nil:
    section.add "blockToken", valid_402656382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656383 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Security-Token", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Signature")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Signature", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Algorithm", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Date")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Date", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Credential")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Credential", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656403: Call_GetSnapshotBlock_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
                                                                                         ## 
  let valid = call_402656403.validator(path, query, header, formData, body, _)
  let scheme = call_402656403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656403.makeUrl(scheme.get, call_402656403.host, call_402656403.base,
                                   call_402656403.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656403, uri, valid, _)

proc call*(call_402656452: Call_GetSnapshotBlock_402656288; snapshotId: string;
           blockIndex: int; blockToken: string): Recallable =
  ## getSnapshotBlock
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ##   
                                                                           ## snapshotId: string (required)
                                                                           ##             
                                                                           ## : 
                                                                           ## The 
                                                                           ## ID 
                                                                           ## of 
                                                                           ## the 
                                                                           ## snapshot 
                                                                           ## containing 
                                                                           ## the 
                                                                           ## block 
                                                                           ## from 
                                                                           ## which 
                                                                           ## to 
                                                                           ## get 
                                                                           ## data.
  ##   
                                                                                   ## blockIndex: int (required)
                                                                                   ##             
                                                                                   ## : 
                                                                                   ## <p>The 
                                                                                   ## block 
                                                                                   ## index 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## block 
                                                                                   ## from 
                                                                                   ## which 
                                                                                   ## to 
                                                                                   ## get 
                                                                                   ## data.</p> 
                                                                                   ## <p>Obtain 
                                                                                   ## the 
                                                                                   ## <code>BlockIndex</code> 
                                                                                   ## by 
                                                                                   ## running 
                                                                                   ## the 
                                                                                   ## <code>ListChangedBlocks</code> 
                                                                                   ## or 
                                                                                   ## <code>ListSnapshotBlocks</code> 
                                                                                   ## operations.</p>
  ##   
                                                                                                     ## blockToken: string (required)
                                                                                                     ##             
                                                                                                     ## : 
                                                                                                     ## <p>The 
                                                                                                     ## block 
                                                                                                     ## token 
                                                                                                     ## of 
                                                                                                     ## the 
                                                                                                     ## block 
                                                                                                     ## from 
                                                                                                     ## which 
                                                                                                     ## to 
                                                                                                     ## get 
                                                                                                     ## data.</p> 
                                                                                                     ## <p>Obtain 
                                                                                                     ## the 
                                                                                                     ## <code>BlockToken</code> 
                                                                                                     ## by 
                                                                                                     ## running 
                                                                                                     ## the 
                                                                                                     ## <code>ListChangedBlocks</code> 
                                                                                                     ## or 
                                                                                                     ## <code>ListSnapshotBlocks</code> 
                                                                                                     ## operations.</p>
  var path_402656453 = newJObject()
  var query_402656455 = newJObject()
  add(path_402656453, "snapshotId", newJString(snapshotId))
  add(path_402656453, "blockIndex", newJInt(blockIndex))
  add(query_402656455, "blockToken", newJString(blockToken))
  result = call_402656452.call(path_402656453, query_402656455, nil, nil, nil)

var getSnapshotBlock* = Call_GetSnapshotBlock_402656288(
    name: "getSnapshotBlock", meth: HttpMethod.HttpGet,
    host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks/{blockIndex}#blockToken",
    validator: validate_GetSnapshotBlock_402656289, base: "/",
    makeUrl: url_GetSnapshotBlock_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangedBlocks_402656484 = ref object of OpenApiRestCall_402656038
proc url_ListChangedBlocks_402656486(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "secondSnapshotId" in path,
         "`secondSnapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
                 (kind: VariableSegment, value: "secondSnapshotId"),
                 (kind: ConstantSegment, value: "/changedblocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListChangedBlocks_402656485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   secondSnapshotId: JString (required)
                                 ##                   : <p>The ID of the second snapshot to use for the comparison.</p> <important> <p>The <code>SecondSnapshotId</code> parameter must be specified with a <code>FirstSnapshotID</code> parameter; otherwise, an error occurs.</p> </important>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `secondSnapshotId` field"
  var valid_402656487 = path.getOrDefault("secondSnapshotId")
  valid_402656487 = validateParameter(valid_402656487, JString, required = true,
                                      default = nil)
  if valid_402656487 != nil:
    section.add "secondSnapshotId", valid_402656487
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The number of results to return.
  ##   
                                                                                   ## firstSnapshotId: JString
                                                                                   ##                  
                                                                                   ## : 
                                                                                   ## <p>The 
                                                                                   ## ID 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## first 
                                                                                   ## snapshot 
                                                                                   ## to 
                                                                                   ## use 
                                                                                   ## for 
                                                                                   ## the 
                                                                                   ## comparison.</p> 
                                                                                   ## <important> 
                                                                                   ## <p>The 
                                                                                   ## <code>FirstSnapshotID</code> 
                                                                                   ## parameter 
                                                                                   ## must 
                                                                                   ## be 
                                                                                   ## specified 
                                                                                   ## with 
                                                                                   ## a 
                                                                                   ## <code>SecondSnapshotId</code> 
                                                                                   ## parameter; 
                                                                                   ## otherwise, 
                                                                                   ## an 
                                                                                   ## error 
                                                                                   ## occurs.</p> 
                                                                                   ## </important>
  ##   
                                                                                                  ## MaxResults: JString
                                                                                                  ##             
                                                                                                  ## : 
                                                                                                  ## Pagination 
                                                                                                  ## limit
  ##   
                                                                                                          ## startingBlockIndex: JInt
                                                                                                          ##                     
                                                                                                          ## : 
                                                                                                          ## <p>The 
                                                                                                          ## block 
                                                                                                          ## index 
                                                                                                          ## from 
                                                                                                          ## which 
                                                                                                          ## the 
                                                                                                          ## comparison 
                                                                                                          ## should 
                                                                                                          ## start.</p> 
                                                                                                          ## <p>The 
                                                                                                          ## list 
                                                                                                          ## in 
                                                                                                          ## the 
                                                                                                          ## response 
                                                                                                          ## will 
                                                                                                          ## start 
                                                                                                          ## from 
                                                                                                          ## this 
                                                                                                          ## block 
                                                                                                          ## index 
                                                                                                          ## or 
                                                                                                          ## the 
                                                                                                          ## next 
                                                                                                          ## valid 
                                                                                                          ## block 
                                                                                                          ## index 
                                                                                                          ## in 
                                                                                                          ## the 
                                                                                                          ## snapshots.</p>
  ##   
                                                                                                                           ## NextToken: JString
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  ##   
                                                                                                                                   ## pageToken: JString
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## token 
                                                                                                                                   ## to 
                                                                                                                                   ## request 
                                                                                                                                   ## the 
                                                                                                                                   ## next 
                                                                                                                                   ## page 
                                                                                                                                   ## of 
                                                                                                                                   ## results.
  section = newJObject()
  var valid_402656488 = query.getOrDefault("maxResults")
  valid_402656488 = validateParameter(valid_402656488, JInt, required = false,
                                      default = nil)
  if valid_402656488 != nil:
    section.add "maxResults", valid_402656488
  var valid_402656489 = query.getOrDefault("firstSnapshotId")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "firstSnapshotId", valid_402656489
  var valid_402656490 = query.getOrDefault("MaxResults")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "MaxResults", valid_402656490
  var valid_402656491 = query.getOrDefault("startingBlockIndex")
  valid_402656491 = validateParameter(valid_402656491, JInt, required = false,
                                      default = nil)
  if valid_402656491 != nil:
    section.add "startingBlockIndex", valid_402656491
  var valid_402656492 = query.getOrDefault("NextToken")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "NextToken", valid_402656492
  var valid_402656493 = query.getOrDefault("pageToken")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "pageToken", valid_402656493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656494 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Security-Token", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Signature")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Signature", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Algorithm", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Date")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Date", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Credential")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Credential", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_ListChangedBlocks_402656484;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_ListChangedBlocks_402656484;
           secondSnapshotId: string; maxResults: int = 0;
           firstSnapshotId: string = ""; MaxResults: string = "";
           startingBlockIndex: int = 0; NextToken: string = "";
           pageToken: string = ""): Recallable =
  ## listChangedBlocks
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ##   
                                                                                                                                                                   ## maxResults: int
                                                                                                                                                                   ##             
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## The 
                                                                                                                                                                   ## number 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## results 
                                                                                                                                                                   ## to 
                                                                                                                                                                   ## return.
  ##   
                                                                                                                                                                             ## firstSnapshotId: string
                                                                                                                                                                             ##                  
                                                                                                                                                                             ## : 
                                                                                                                                                                             ## <p>The 
                                                                                                                                                                             ## ID 
                                                                                                                                                                             ## of 
                                                                                                                                                                             ## the 
                                                                                                                                                                             ## first 
                                                                                                                                                                             ## snapshot 
                                                                                                                                                                             ## to 
                                                                                                                                                                             ## use 
                                                                                                                                                                             ## for 
                                                                                                                                                                             ## the 
                                                                                                                                                                             ## comparison.</p> 
                                                                                                                                                                             ## <important> 
                                                                                                                                                                             ## <p>The 
                                                                                                                                                                             ## <code>FirstSnapshotID</code> 
                                                                                                                                                                             ## parameter 
                                                                                                                                                                             ## must 
                                                                                                                                                                             ## be 
                                                                                                                                                                             ## specified 
                                                                                                                                                                             ## with 
                                                                                                                                                                             ## a 
                                                                                                                                                                             ## <code>SecondSnapshotId</code> 
                                                                                                                                                                             ## parameter; 
                                                                                                                                                                             ## otherwise, 
                                                                                                                                                                             ## an 
                                                                                                                                                                             ## error 
                                                                                                                                                                             ## occurs.</p> 
                                                                                                                                                                             ## </important>
  ##   
                                                                                                                                                                                            ## secondSnapshotId: string (required)
                                                                                                                                                                                            ##                   
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## <p>The 
                                                                                                                                                                                            ## ID 
                                                                                                                                                                                            ## of 
                                                                                                                                                                                            ## the 
                                                                                                                                                                                            ## second 
                                                                                                                                                                                            ## snapshot 
                                                                                                                                                                                            ## to 
                                                                                                                                                                                            ## use 
                                                                                                                                                                                            ## for 
                                                                                                                                                                                            ## the 
                                                                                                                                                                                            ## comparison.</p> 
                                                                                                                                                                                            ## <important> 
                                                                                                                                                                                            ## <p>The 
                                                                                                                                                                                            ## <code>SecondSnapshotId</code> 
                                                                                                                                                                                            ## parameter 
                                                                                                                                                                                            ## must 
                                                                                                                                                                                            ## be 
                                                                                                                                                                                            ## specified 
                                                                                                                                                                                            ## with 
                                                                                                                                                                                            ## a 
                                                                                                                                                                                            ## <code>FirstSnapshotID</code> 
                                                                                                                                                                                            ## parameter; 
                                                                                                                                                                                            ## otherwise, 
                                                                                                                                                                                            ## an 
                                                                                                                                                                                            ## error 
                                                                                                                                                                                            ## occurs.</p> 
                                                                                                                                                                                            ## </important>
  ##   
                                                                                                                                                                                                           ## MaxResults: string
                                                                                                                                                                                                           ##             
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                           ## limit
  ##   
                                                                                                                                                                                                                   ## startingBlockIndex: int
                                                                                                                                                                                                                   ##                     
                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                   ## <p>The 
                                                                                                                                                                                                                   ## block 
                                                                                                                                                                                                                   ## index 
                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                   ## which 
                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                   ## comparison 
                                                                                                                                                                                                                   ## should 
                                                                                                                                                                                                                   ## start.</p> 
                                                                                                                                                                                                                   ## <p>The 
                                                                                                                                                                                                                   ## list 
                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                   ## will 
                                                                                                                                                                                                                   ## start 
                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                   ## this 
                                                                                                                                                                                                                   ## block 
                                                                                                                                                                                                                   ## index 
                                                                                                                                                                                                                   ## or 
                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                                   ## valid 
                                                                                                                                                                                                                   ## block 
                                                                                                                                                                                                                   ## index 
                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                   ## snapshots.</p>
  ##   
                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                    ## token
  ##   
                                                                                                                                                                                                                                            ## pageToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## request 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## next 
                                                                                                                                                                                                                                            ## page 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## results.
  var path_402656503 = newJObject()
  var query_402656504 = newJObject()
  add(query_402656504, "maxResults", newJInt(maxResults))
  add(query_402656504, "firstSnapshotId", newJString(firstSnapshotId))
  add(path_402656503, "secondSnapshotId", newJString(secondSnapshotId))
  add(query_402656504, "MaxResults", newJString(MaxResults))
  add(query_402656504, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_402656504, "NextToken", newJString(NextToken))
  add(query_402656504, "pageToken", newJString(pageToken))
  result = call_402656502.call(path_402656503, query_402656504, nil, nil, nil)

var listChangedBlocks* = Call_ListChangedBlocks_402656484(
    name: "listChangedBlocks", meth: HttpMethod.HttpGet,
    host: "ebs.amazonaws.com",
    route: "/snapshots/{secondSnapshotId}/changedblocks",
    validator: validate_ListChangedBlocks_402656485, base: "/",
    makeUrl: url_ListChangedBlocks_402656486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSnapshotBlocks_402656505 = ref object of OpenApiRestCall_402656038
proc url_ListSnapshotBlocks_402656507(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
                 (kind: VariableSegment, value: "snapshotId"),
                 (kind: ConstantSegment, value: "/blocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSnapshotBlocks_402656506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
                                 ##             : The ID of the snapshot from which to get block indexes and block tokens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `snapshotId` field"
  var valid_402656508 = path.getOrDefault("snapshotId")
  valid_402656508 = validateParameter(valid_402656508, JString, required = true,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "snapshotId", valid_402656508
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The number of results to return.
  ##   
                                                                                   ## MaxResults: JString
                                                                                   ##             
                                                                                   ## : 
                                                                                   ## Pagination 
                                                                                   ## limit
  ##   
                                                                                           ## startingBlockIndex: JInt
                                                                                           ##                     
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## block 
                                                                                           ## index 
                                                                                           ## from 
                                                                                           ## which 
                                                                                           ## the 
                                                                                           ## list 
                                                                                           ## should 
                                                                                           ## start. 
                                                                                           ## The 
                                                                                           ## list 
                                                                                           ## in 
                                                                                           ## the 
                                                                                           ## response 
                                                                                           ## will 
                                                                                           ## start 
                                                                                           ## from 
                                                                                           ## this 
                                                                                           ## block 
                                                                                           ## index 
                                                                                           ## or 
                                                                                           ## the 
                                                                                           ## next 
                                                                                           ## valid 
                                                                                           ## block 
                                                                                           ## index 
                                                                                           ## in 
                                                                                           ## the 
                                                                                           ## snapshot.
  ##   
                                                                                                       ## NextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## token
  ##   
                                                                                                               ## pageToken: JString
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## token 
                                                                                                               ## to 
                                                                                                               ## request 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## page 
                                                                                                               ## of 
                                                                                                               ## results.
  section = newJObject()
  var valid_402656509 = query.getOrDefault("maxResults")
  valid_402656509 = validateParameter(valid_402656509, JInt, required = false,
                                      default = nil)
  if valid_402656509 != nil:
    section.add "maxResults", valid_402656509
  var valid_402656510 = query.getOrDefault("MaxResults")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "MaxResults", valid_402656510
  var valid_402656511 = query.getOrDefault("startingBlockIndex")
  valid_402656511 = validateParameter(valid_402656511, JInt, required = false,
                                      default = nil)
  if valid_402656511 != nil:
    section.add "startingBlockIndex", valid_402656511
  var valid_402656512 = query.getOrDefault("NextToken")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "NextToken", valid_402656512
  var valid_402656513 = query.getOrDefault("pageToken")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "pageToken", valid_402656513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656521: Call_ListSnapshotBlocks_402656505;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
                                                                                         ## 
  let valid = call_402656521.validator(path, query, header, formData, body, _)
  let scheme = call_402656521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656521.makeUrl(scheme.get, call_402656521.host, call_402656521.base,
                                   call_402656521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656521, uri, valid, _)

proc call*(call_402656522: Call_ListSnapshotBlocks_402656505;
           snapshotId: string; maxResults: int = 0; MaxResults: string = "";
           startingBlockIndex: int = 0; NextToken: string = "";
           pageToken: string = ""): Recallable =
  ## listSnapshotBlocks
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ##   
                                                                                                     ## maxResults: int
                                                                                                     ##             
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## number 
                                                                                                     ## of 
                                                                                                     ## results 
                                                                                                     ## to 
                                                                                                     ## return.
  ##   
                                                                                                               ## snapshotId: string (required)
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## ID 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## snapshot 
                                                                                                               ## from 
                                                                                                               ## which 
                                                                                                               ## to 
                                                                                                               ## get 
                                                                                                               ## block 
                                                                                                               ## indexes 
                                                                                                               ## and 
                                                                                                               ## block 
                                                                                                               ## tokens.
  ##   
                                                                                                                         ## MaxResults: string
                                                                                                                         ##             
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## limit
  ##   
                                                                                                                                 ## startingBlockIndex: int
                                                                                                                                 ##                     
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## block 
                                                                                                                                 ## index 
                                                                                                                                 ## from 
                                                                                                                                 ## which 
                                                                                                                                 ## the 
                                                                                                                                 ## list 
                                                                                                                                 ## should 
                                                                                                                                 ## start. 
                                                                                                                                 ## The 
                                                                                                                                 ## list 
                                                                                                                                 ## in 
                                                                                                                                 ## the 
                                                                                                                                 ## response 
                                                                                                                                 ## will 
                                                                                                                                 ## start 
                                                                                                                                 ## from 
                                                                                                                                 ## this 
                                                                                                                                 ## block 
                                                                                                                                 ## index 
                                                                                                                                 ## or 
                                                                                                                                 ## the 
                                                                                                                                 ## next 
                                                                                                                                 ## valid 
                                                                                                                                 ## block 
                                                                                                                                 ## index 
                                                                                                                                 ## in 
                                                                                                                                 ## the 
                                                                                                                                 ## snapshot.
  ##   
                                                                                                                                             ## NextToken: string
                                                                                                                                             ##            
                                                                                                                                             ## : 
                                                                                                                                             ## Pagination 
                                                                                                                                             ## token
  ##   
                                                                                                                                                     ## pageToken: string
                                                                                                                                                     ##            
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## token 
                                                                                                                                                     ## to 
                                                                                                                                                     ## request 
                                                                                                                                                     ## the 
                                                                                                                                                     ## next 
                                                                                                                                                     ## page 
                                                                                                                                                     ## of 
                                                                                                                                                     ## results.
  var path_402656523 = newJObject()
  var query_402656524 = newJObject()
  add(query_402656524, "maxResults", newJInt(maxResults))
  add(path_402656523, "snapshotId", newJString(snapshotId))
  add(query_402656524, "MaxResults", newJString(MaxResults))
  add(query_402656524, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_402656524, "NextToken", newJString(NextToken))
  add(query_402656524, "pageToken", newJString(pageToken))
  result = call_402656522.call(path_402656523, query_402656524, nil, nil, nil)

var listSnapshotBlocks* = Call_ListSnapshotBlocks_402656505(
    name: "listSnapshotBlocks", meth: HttpMethod.HttpGet,
    host: "ebs.amazonaws.com", route: "/snapshots/{snapshotId}/blocks",
    validator: validate_ListSnapshotBlocks_402656506, base: "/",
    makeUrl: url_ListSnapshotBlocks_402656507,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}