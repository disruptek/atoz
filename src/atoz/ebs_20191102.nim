
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetSnapshotBlock_21625770 = ref object of OpenApiRestCall_21625426
proc url_GetSnapshotBlock_21625772(protocol: Scheme; host: string; base: string;
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

proc validate_GetSnapshotBlock_21625771(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625886 = path.getOrDefault("snapshotId")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "snapshotId", valid_21625886
  var valid_21625887 = path.getOrDefault("blockIndex")
  valid_21625887 = validateParameter(valid_21625887, JInt, required = true,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "blockIndex", valid_21625887
  result.add "path", section
  ## parameters in `query` object:
  ##   blockToken: JString (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>BlockToken</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `blockToken` field"
  var valid_21625888 = query.getOrDefault("blockToken")
  valid_21625888 = validateParameter(valid_21625888, JString, required = true,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "blockToken", valid_21625888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625889 = header.getOrDefault("X-Amz-Date")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Date", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Security-Token", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Algorithm", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-Signature")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-Signature", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625894
  var valid_21625895 = header.getOrDefault("X-Amz-Credential")
  valid_21625895 = validateParameter(valid_21625895, JString, required = false,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "X-Amz-Credential", valid_21625895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625920: Call_GetSnapshotBlock_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_21625920.validator(path, query, header, formData, body, _)
  let scheme = call_21625920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625920.makeUrl(scheme.get, call_21625920.host, call_21625920.base,
                               call_21625920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625920, uri, valid, _)

proc call*(call_21625983: Call_GetSnapshotBlock_21625770; blockToken: string;
          snapshotId: string; blockIndex: int): Recallable =
  ## getSnapshotBlock
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ##   blockToken: string (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>BlockToken</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: int (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>BlockIndex</code> by running the <code>ListChangedBlocks</code> or <code>ListSnapshotBlocks</code> operations.</p>
  var path_21625985 = newJObject()
  var query_21625987 = newJObject()
  add(query_21625987, "blockToken", newJString(blockToken))
  add(path_21625985, "snapshotId", newJString(snapshotId))
  add(path_21625985, "blockIndex", newJInt(blockIndex))
  result = call_21625983.call(path_21625985, query_21625987, nil, nil, nil)

var getSnapshotBlock* = Call_GetSnapshotBlock_21625770(name: "getSnapshotBlock",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks/{blockIndex}#blockToken",
    validator: validate_GetSnapshotBlock_21625771, base: "/",
    makeUrl: url_GetSnapshotBlock_21625772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangedBlocks_21626024 = ref object of OpenApiRestCall_21625426
proc url_ListChangedBlocks_21626026(protocol: Scheme; host: string; base: string;
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

proc validate_ListChangedBlocks_21626025(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626027 = path.getOrDefault("secondSnapshotId")
  valid_21626027 = validateParameter(valid_21626027, JString, required = true,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "secondSnapshotId", valid_21626027
  result.add "path", section
  ## parameters in `query` object:
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   firstSnapshotId: JString
  ##                  : <p>The ID of the first snapshot to use for the comparison.</p> <important> <p>The <code>FirstSnapshotID</code> parameter must be specified with a <code>SecondSnapshotId</code> parameter; otherwise, an error occurs.</p> </important>
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The number of results to return.
  ##   startingBlockIndex: JInt
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626028 = query.getOrDefault("pageToken")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "pageToken", valid_21626028
  var valid_21626029 = query.getOrDefault("firstSnapshotId")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "firstSnapshotId", valid_21626029
  var valid_21626030 = query.getOrDefault("NextToken")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "NextToken", valid_21626030
  var valid_21626031 = query.getOrDefault("maxResults")
  valid_21626031 = validateParameter(valid_21626031, JInt, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "maxResults", valid_21626031
  var valid_21626032 = query.getOrDefault("startingBlockIndex")
  valid_21626032 = validateParameter(valid_21626032, JInt, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "startingBlockIndex", valid_21626032
  var valid_21626033 = query.getOrDefault("MaxResults")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "MaxResults", valid_21626033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_ListChangedBlocks_21626024; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_ListChangedBlocks_21626024;
          secondSnapshotId: string; pageToken: string = "";
          firstSnapshotId: string = ""; NextToken: string = ""; maxResults: int = 0;
          startingBlockIndex: int = 0; MaxResults: string = ""): Recallable =
  ## listChangedBlocks
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   firstSnapshotId: string
  ##                  : <p>The ID of the first snapshot to use for the comparison.</p> <important> <p>The <code>FirstSnapshotID</code> parameter must be specified with a <code>SecondSnapshotId</code> parameter; otherwise, an error occurs.</p> </important>
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The number of results to return.
  ##   secondSnapshotId: string (required)
  ##                   : <p>The ID of the second snapshot to use for the comparison.</p> <important> <p>The <code>SecondSnapshotId</code> parameter must be specified with a <code>FirstSnapshotID</code> parameter; otherwise, an error occurs.</p> </important>
  ##   startingBlockIndex: int
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626043 = newJObject()
  var query_21626044 = newJObject()
  add(query_21626044, "pageToken", newJString(pageToken))
  add(query_21626044, "firstSnapshotId", newJString(firstSnapshotId))
  add(query_21626044, "NextToken", newJString(NextToken))
  add(query_21626044, "maxResults", newJInt(maxResults))
  add(path_21626043, "secondSnapshotId", newJString(secondSnapshotId))
  add(query_21626044, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_21626044, "MaxResults", newJString(MaxResults))
  result = call_21626042.call(path_21626043, query_21626044, nil, nil, nil)

var listChangedBlocks* = Call_ListChangedBlocks_21626024(name: "listChangedBlocks",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{secondSnapshotId}/changedblocks",
    validator: validate_ListChangedBlocks_21626025, base: "/",
    makeUrl: url_ListChangedBlocks_21626026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSnapshotBlocks_21626046 = ref object of OpenApiRestCall_21625426
proc url_ListSnapshotBlocks_21626048(protocol: Scheme; host: string; base: string;
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

proc validate_ListSnapshotBlocks_21626047(path: JsonNode; query: JsonNode;
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
  var valid_21626049 = path.getOrDefault("snapshotId")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "snapshotId", valid_21626049
  result.add "path", section
  ## parameters in `query` object:
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The number of results to return.
  ##   startingBlockIndex: JInt
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626050 = query.getOrDefault("pageToken")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "pageToken", valid_21626050
  var valid_21626051 = query.getOrDefault("NextToken")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "NextToken", valid_21626051
  var valid_21626052 = query.getOrDefault("maxResults")
  valid_21626052 = validateParameter(valid_21626052, JInt, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "maxResults", valid_21626052
  var valid_21626053 = query.getOrDefault("startingBlockIndex")
  valid_21626053 = validateParameter(valid_21626053, JInt, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "startingBlockIndex", valid_21626053
  var valid_21626054 = query.getOrDefault("MaxResults")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "MaxResults", valid_21626054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626055 = header.getOrDefault("X-Amz-Date")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Date", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Security-Token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Algorithm", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Signature")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Signature", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Credential")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Credential", valid_21626061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626062: Call_ListSnapshotBlocks_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_21626062.validator(path, query, header, formData, body, _)
  let scheme = call_21626062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626062.makeUrl(scheme.get, call_21626062.host, call_21626062.base,
                               call_21626062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626062, uri, valid, _)

proc call*(call_21626063: Call_ListSnapshotBlocks_21626046; snapshotId: string;
          pageToken: string = ""; NextToken: string = ""; maxResults: int = 0;
          startingBlockIndex: int = 0; MaxResults: string = ""): Recallable =
  ## listSnapshotBlocks
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The number of results to return.
  ##   startingBlockIndex: int
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626064 = newJObject()
  var query_21626065 = newJObject()
  add(query_21626065, "pageToken", newJString(pageToken))
  add(path_21626064, "snapshotId", newJString(snapshotId))
  add(query_21626065, "NextToken", newJString(NextToken))
  add(query_21626065, "maxResults", newJInt(maxResults))
  add(query_21626065, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_21626065, "MaxResults", newJString(MaxResults))
  result = call_21626063.call(path_21626064, query_21626065, nil, nil, nil)

var listSnapshotBlocks* = Call_ListSnapshotBlocks_21626046(
    name: "listSnapshotBlocks", meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks",
    validator: validate_ListSnapshotBlocks_21626047, base: "/",
    makeUrl: url_ListSnapshotBlocks_21626048, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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