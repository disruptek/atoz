
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ebs.us-west-2.amazonaws.com",
                           "eu-west-2": "ebs.eu-west-2.amazonaws.com", "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ebs.eu-central-1.amazonaws.com",
                           "us-east-2": "ebs.us-east-2.amazonaws.com",
                           "us-east-1": "ebs.us-east-1.amazonaws.com", "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ebs.ap-south-1.amazonaws.com",
                           "eu-north-1": "ebs.eu-north-1.amazonaws.com", "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ebs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ebs.eu-west-3.amazonaws.com",
                           "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ebs.sa-east-1.amazonaws.com",
                           "eu-west-1": "ebs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetSnapshotBlock_610987 = ref object of OpenApiRestCall_610649
proc url_GetSnapshotBlock_610989(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSnapshotBlock_610988(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: JInt (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>BlockIndex</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `snapshotId` field"
  var valid_611115 = path.getOrDefault("snapshotId")
  valid_611115 = validateParameter(valid_611115, JString, required = true,
                                 default = nil)
  if valid_611115 != nil:
    section.add "snapshotId", valid_611115
  var valid_611116 = path.getOrDefault("blockIndex")
  valid_611116 = validateParameter(valid_611116, JInt, required = true, default = nil)
  if valid_611116 != nil:
    section.add "blockIndex", valid_611116
  result.add "path", section
  ## parameters in `query` object:
  ##   blockToken: JString (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>BlockToken</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `blockToken` field"
  var valid_611117 = query.getOrDefault("blockToken")
  valid_611117 = validateParameter(valid_611117, JString, required = true,
                                 default = nil)
  if valid_611117 != nil:
    section.add "blockToken", valid_611117
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
  var valid_611118 = header.getOrDefault("X-Amz-Signature")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Signature", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Content-Sha256", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Date")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Date", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-Credential")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-Credential", valid_611121
  var valid_611122 = header.getOrDefault("X-Amz-Security-Token")
  valid_611122 = validateParameter(valid_611122, JString, required = false,
                                 default = nil)
  if valid_611122 != nil:
    section.add "X-Amz-Security-Token", valid_611122
  var valid_611123 = header.getOrDefault("X-Amz-Algorithm")
  valid_611123 = validateParameter(valid_611123, JString, required = false,
                                 default = nil)
  if valid_611123 != nil:
    section.add "X-Amz-Algorithm", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-SignedHeaders", valid_611124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611147: Call_GetSnapshotBlock_610987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_611147.validator(path, query, header, formData, body)
  let scheme = call_611147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611147.url(scheme.get, call_611147.host, call_611147.base,
                         call_611147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611147, url, valid)

proc call*(call_611218: Call_GetSnapshotBlock_610987; snapshotId: string;
          blockIndex: int; blockToken: string): Recallable =
  ## getSnapshotBlock
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: int (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>BlockIndex</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  ##   blockToken: string (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>BlockToken</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  var path_611219 = newJObject()
  var query_611221 = newJObject()
  add(path_611219, "snapshotId", newJString(snapshotId))
  add(path_611219, "blockIndex", newJInt(blockIndex))
  add(query_611221, "blockToken", newJString(blockToken))
  result = call_611218.call(path_611219, query_611221, nil, nil, nil)

var getSnapshotBlock* = Call_GetSnapshotBlock_610987(name: "getSnapshotBlock",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks/{blockIndex}#blockToken",
    validator: validate_GetSnapshotBlock_610988, base: "/",
    url: url_GetSnapshotBlock_610989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangedBlocks_611260 = ref object of OpenApiRestCall_610649
proc url_ListChangedBlocks_611262(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListChangedBlocks_611261(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611263 = path.getOrDefault("secondSnapshotId")
  valid_611263 = validateParameter(valid_611263, JString, required = true,
                                 default = nil)
  if valid_611263 != nil:
    section.add "secondSnapshotId", valid_611263
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: JString
  ##                  : <p>The ID of the first snapshot to use for the comparison.</p> <important> <p>The <code>FirstSnapshotID</code> parameter must be specified with a <code>SecondSnapshotId</code> parameter; otherwise, an error occurs.</p> </important>
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_611264 = query.getOrDefault("MaxResults")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "MaxResults", valid_611264
  var valid_611265 = query.getOrDefault("NextToken")
  valid_611265 = validateParameter(valid_611265, JString, required = false,
                                 default = nil)
  if valid_611265 != nil:
    section.add "NextToken", valid_611265
  var valid_611266 = query.getOrDefault("pageToken")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "pageToken", valid_611266
  var valid_611267 = query.getOrDefault("startingBlockIndex")
  valid_611267 = validateParameter(valid_611267, JInt, required = false, default = nil)
  if valid_611267 != nil:
    section.add "startingBlockIndex", valid_611267
  var valid_611268 = query.getOrDefault("firstSnapshotId")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "firstSnapshotId", valid_611268
  var valid_611269 = query.getOrDefault("maxResults")
  valid_611269 = validateParameter(valid_611269, JInt, required = false, default = nil)
  if valid_611269 != nil:
    section.add "maxResults", valid_611269
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
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_ListChangedBlocks_611260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_ListChangedBlocks_611260; secondSnapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; firstSnapshotId: string = ""; maxResults: int = 0): Recallable =
  ## listChangedBlocks
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   secondSnapshotId: string (required)
  ##                   : <p>The ID of the second snapshot to use for the comparison.</p> <important> <p>The <code>SecondSnapshotId</code> parameter must be specified with a <code>FirstSnapshotID</code> parameter; otherwise, an error occurs.</p> </important>
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: string
  ##                  : <p>The ID of the first snapshot to use for the comparison.</p> <important> <p>The <code>FirstSnapshotID</code> parameter must be specified with a <code>SecondSnapshotId</code> parameter; otherwise, an error occurs.</p> </important>
  ##   maxResults: int
  ##             : The number of results to return.
  var path_611279 = newJObject()
  var query_611280 = newJObject()
  add(query_611280, "MaxResults", newJString(MaxResults))
  add(query_611280, "NextToken", newJString(NextToken))
  add(path_611279, "secondSnapshotId", newJString(secondSnapshotId))
  add(query_611280, "pageToken", newJString(pageToken))
  add(query_611280, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_611280, "firstSnapshotId", newJString(firstSnapshotId))
  add(query_611280, "maxResults", newJInt(maxResults))
  result = call_611278.call(path_611279, query_611280, nil, nil, nil)

var listChangedBlocks* = Call_ListChangedBlocks_611260(name: "listChangedBlocks",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{secondSnapshotId}/changedblocks",
    validator: validate_ListChangedBlocks_611261, base: "/",
    url: url_ListChangedBlocks_611262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSnapshotBlocks_611281 = ref object of OpenApiRestCall_610649
proc url_ListSnapshotBlocks_611283(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListSnapshotBlocks_611282(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611284 = path.getOrDefault("snapshotId")
  valid_611284 = validateParameter(valid_611284, JString, required = true,
                                 default = nil)
  if valid_611284 != nil:
    section.add "snapshotId", valid_611284
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_611285 = query.getOrDefault("MaxResults")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "MaxResults", valid_611285
  var valid_611286 = query.getOrDefault("NextToken")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "NextToken", valid_611286
  var valid_611287 = query.getOrDefault("pageToken")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "pageToken", valid_611287
  var valid_611288 = query.getOrDefault("startingBlockIndex")
  valid_611288 = validateParameter(valid_611288, JInt, required = false, default = nil)
  if valid_611288 != nil:
    section.add "startingBlockIndex", valid_611288
  var valid_611289 = query.getOrDefault("maxResults")
  valid_611289 = validateParameter(valid_611289, JInt, required = false, default = nil)
  if valid_611289 != nil:
    section.add "maxResults", valid_611289
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
  var valid_611290 = header.getOrDefault("X-Amz-Signature")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Signature", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Content-Sha256", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Date")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Date", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Credential")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Credential", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Security-Token")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Security-Token", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Algorithm")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Algorithm", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-SignedHeaders", valid_611296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_ListSnapshotBlocks_611281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_ListSnapshotBlocks_611281; snapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; maxResults: int = 0): Recallable =
  ## listSnapshotBlocks
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: int
  ##             : The number of results to return.
  var path_611299 = newJObject()
  var query_611300 = newJObject()
  add(path_611299, "snapshotId", newJString(snapshotId))
  add(query_611300, "MaxResults", newJString(MaxResults))
  add(query_611300, "NextToken", newJString(NextToken))
  add(query_611300, "pageToken", newJString(pageToken))
  add(query_611300, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_611300, "maxResults", newJInt(maxResults))
  result = call_611298.call(path_611299, query_611300, nil, nil, nil)

var listSnapshotBlocks* = Call_ListSnapshotBlocks_611281(
    name: "listSnapshotBlocks", meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks",
    validator: validate_ListSnapshotBlocks_611282, base: "/",
    url: url_ListSnapshotBlocks_611283, schemes: {Scheme.Https, Scheme.Http})
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
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
